#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define ROM_SIZE  0x2000
#define SIZE      0x2100
#define DATA_BASE 0x2000
#define ENTRY_A0  (DATA_BASE + 1)
#define ENTRY_A1  (DATA_BASE + 2)
#define MAX_HISTORY 2000

typedef struct {
    uint16_t p, i;       
    int16_t a, d;        
    uint8_t memory[SIZE]; 
    int halt;            
} SmolCPU;

SmolCPU history[MAX_HISTORY];
int history_ptr = 0;

int16_t execute_alu(SmolCPU *cpu, uint8_t opc, int16_t x, int16_t y) {
    int16_t x0 = (opc & 0x20) ? 0 : x;
    int16_t x1 = (opc & 0x10) ? ~x0 : x0;
    int16_t y0 = (opc & 0x08) ? 0 : y;
    int16_t y1 = (opc & 0x04) ? ~y0 : y0;
    
    int16_t z0;
    if (opc & 0x02) {
        if (opc & 0x01)
            z0 = (y1 < 0) ? (x1 >> (0 - y1)) : (x1 << y1);
        else 
            z0 = (x1 < 0) ? (y1 >> (0 - x1)) : (y1 << x1);
    } else {
        z0 = (opc & 0x01) ? (x1 + y1) : (x1 & y1);
    }

    int16_t z1 = z0;
    if (opc & 0x80) {
        z1 = 0;
        for(int k=0; k<=15; k++) if(z0 & (1 << k)) z1 |= (1 << (15-k));
    }
    return (opc & 0x40) ? ~z1 : z1;
}

void step(SmolCPU *cpu) {
    if (cpu->halt) return;

    if (history_ptr < MAX_HISTORY) {
        history[history_ptr++] = *cpu;
    }

    uint16_t instr = cpu->memory[cpu->p] | (cpu->memory[cpu->p + 1] << 8);
    cpu->i = instr;
    cpu->p += 2;

    uint8_t nan = instr & 0x01;
    uint8_t src = (instr >> 1) & 0x01;
    uint8_t opc = (instr >> 2) & 0xFF;
    uint8_t dst = (instr >> 10) & 0x07;
    uint8_t jmp = (instr >> 13) & 0x07;

    int16_t m = (int8_t)cpu->memory[(uint16_t)cpu->a];
    int16_t y = src ? m : cpu->a;
    int16_t z = execute_alu(cpu, opc, cpu->d, y);

    if (nan) {
        if (dst & 0x02) cpu->d = z;
        if (dst & 0x04) cpu->a = z;
        if (dst & 0x01) cpu->memory[(uint16_t)cpu->a] = (uint8_t)z;

        int lt = (z < 0), eq = (z == 0), gt = (z > 0);
        if ((jmp & 0x04 && lt) || (jmp & 0x02 && eq) || (jmp & 0x01 && gt))
            cpu->p = (uint16_t)cpu->a;
    } else {
        cpu->a = (int16_t)((instr & 0x8000) ? (instr | 0x0001) : (instr >> 1));
    }

    if (cpu->p == 0xFFFF) cpu->halt = 1;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <rom.memh>\n", argv[0]);
        return 1;
    }

    SmolCPU cpu = {0};
    FILE *f = fopen(argv[1], "r");
    if (!f) { perror("Failed to open ROM"); return 1; }
    uint32_t addr = 0;
    unsigned int val;
    while (fscanf(f, "%x", &val) != EOF && addr < ROM_SIZE) 
        cpu.memory[addr++] = (uint8_t)val;
    fclose(f);

    cpu.p = cpu.memory[ENTRY_A0] | (cpu.memory[ENTRY_A1] << 8);

    char cmd[256];
    printf("SMOL Debugger\n");
    printf("Commands: [s]tep, [b]ack, [r]egs, [a] <hex>, [d] <hex>, [m] <addr> [val], [q]uit\n");

    while (1) {
        printf("(smol) ");
        if (!fgets(cmd, sizeof(cmd), stdin)) break;

        if (cmd[0] == 's') {
            step(&cpu);
            printf("PC: 0x%04X\n", cpu.p);
        } else if (cmd[0] == 'b') {
            if (history_ptr > 0) {
                cpu = history[--history_ptr];
                printf("Back to PC: 0x%04X\n", cpu.p);
            } else printf("No history.\n");
        } else if (cmd[0] == 'r') {
            printf("A: 0x%04X  D: 0x%04X  P: 0x%04X  I: 0x%04X\n", (uint16_t)cpu.a, (uint16_t)cpu.d, cpu.p, cpu.i);
        } else if (cmd[0] == 'a') {
            unsigned int v;
            if (sscanf(cmd, "a %x", &v) == 1) { cpu.a = (int16_t)v; printf("A set to 0x%04X\n", (uint16_t)cpu.a); }
        } else if (cmd[0] == 'd') {
            unsigned int v;
            if (sscanf(cmd, "d %x", &v) == 1) { cpu.d = (int16_t)v; printf("D set to 0x%04X\n", (uint16_t)cpu.d); }
        } else if (cmd[0] == 'm') {
            unsigned int m_addr, m_val;
            int args = sscanf(cmd, "m %x %x", &m_addr, &m_val);
            if (args == 1 && m_addr < SIZE) {
                printf("Mem[0x%04X] = 0x%02X\n", m_addr, cpu.memory[m_addr]);
            } else if (args == 2 && m_addr < SIZE) {
                cpu.memory[m_addr] = (uint8_t)m_val;
                printf("Set Mem[0x%04X] = 0x%02X\n", m_addr, cpu.memory[m_addr]);
            } else printf("Invalid command or address.\n");
        } else if (cmd[0] == 'q') break;
    }
    return 0;
}
