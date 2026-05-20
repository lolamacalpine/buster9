# BUSTER-9

## Machine Specs

- **Word Size:** 9-bit
- **Memory Size:** 512 words
- General purpose registers and memory are word-addressable.

## Instructions Format

### R-Type

- **Fields:** `opcode`, `FUNC`, `rA`, `rB`
- **Bit layout:** `8:6 opcode | 5:4 FUNC | 3:2 rA | 1:0 rB`

### C-Type

- **Fields:** `opcode`, `FUNC`, `rA`, `CON`
- **Bit layout:** `8:6 opcode | 5 FUNC | 4:3 rA | 2:0 CON`

### O-Type

- **Fields:** `opcode`, `OFF`
- **Bit layout:** `8:6 opcode | 5:0 OFF`

## General Purpose Registers

| Name | Number | Use                                    |
| ---- | ------ | -------------------------------------- |
| r0   | 00     | General Purpose / Accumulator / Result |
| r1   | 01     | General Purpose / Argument 1           |
| r2   | 10     | General Purpose / Argument 2           |
| r3   | 11     | General purpose / Temp                 |

## Flags Register

| Bit | Name     | Code | UpdateFlags(Result)                               |
| --- | -------- | ---- | ------------------------------------------------- |
| 0   | Zero     | Z    | `Z <- Result == 0`                                |
| 1   | Negative | N    | `N <- (Result)[8] == 1`                           |
| 2   | Carry    | C    | `C <- (rA[8] * rB[8]) + (C8 * (rA[8] xor rB[8]))` |
| 3   | Overflow | V    | `V <- C xor C8`                                   |

**Note:** Carry and overflow flags are only set with adding or subtracting instructions where `Result = rA + rB`, otherwise zero.

## Instruction Set

| Name                  | Opcode/Func | Assembly Syntax | Operation (RTL)                          |
| --------------------- | ----------- | --------------- | ---------------------------------------- |
| Stop                  | `000/00`    | `stop`          | Stops program execution                  |
| Load Word             | `000/01`    | `load rA, (rB)` | `rA <- Mem[rB]`                          |
| Store Word            | `000/10`    | `st (rA), rB`   | `Mem[rA] <- rB`                          |
| Add                   | `000/11`    | `add rA, rB`    | `rA <- rA + rB; UpdateFlags(rA)`         |
| Subtract              | `001/00`    | `sub rA, rB`    | `rA <- rA - rB; UpdateFlags(rA)`         |
| And                   | `001/01`    | `and rA, rB`    | `rA <- rA & rB; UpdateFlags(rA)`         |
| Not                   | `001/10`    | `not rA`        | `rA <- ~rA; UpdateFlags(rA)`             |
| Compare               | `001/11`    | `cmp rA, rB`    | `UpdateFlags(rA - rB)`                   |
| Load Immediate        | `010/0`     | `li rA, CON`    | `rA <- Zext(CON)`                        |
| Add Immediate         | `010/1`     | `addi rA, CON`  | `rA <- rA + Sext(CON); UpdateFlags(rA)`  |
| Or Immediate          | `011/0`     | `ori rA, CON`   | `rA <- rA \| Zext(CON); UpdateFlags(rA)` |
| Shift Left Logical    | `011/1`     | `sll rA, CON`   | `rA <- rA << CON; UpdateFlags(rA)`       |
| Shift Right Logical   | `100/0`     | `srl rA, CON`   | `rA <- rA >> CON; UpdateFlags(rA)`       |
| Jump Register         | `100/1`     | `jr rA`         | `PC <- rA`                               |
| Jump If Greater/Equal | `101`       | `jge LABEL`     | `if (~(N xor V)) PC = PC + Sext(OFF)`    |
| Jump If Not Zero      | `110`       | `jnz LABEL`     | `if (Z == 0) PC = PC + Sext(OFF)`        |
| Jump Offset           | `111`       | `j LABEL`       | `PC <- PC + Sext(OFF)`                   |

**Note on Offsets:** For O-Type instructions, the 6-bit OFF field is calculated as `Addr[LABEL] - (PC + 1)`.

**Note on PC:** The program counter is incremented unconditionally during the fetch stage. Therefore, all instruction logic is relative to the address of the following instruction.

## Assembly

### 1. Register & Operand Syntax

- **Register Naming:** Registers are denoted by a lowercase `r` followed by the index (`r0` through `r3`).
- **Machine Encoding:** Register indices correspond to their 2-bit binary equivalent (`r2 = {10}_2`).
- **Operand Order:** For R-type and C-type instructions, the first operand (`rA`) is both the source and the destination for the result (`rA <- rA op Operand`).

### 2. Mnemonics & Labels

- **Mnemonics:** Instructions (for example, `add`, `sub`) are recommended to be lower case but the assembler is not case-sensitive.
- **Labels:** Labels (for example, `LOOP:`, `DONE:`) are recommended to be ALL CAPS for visibility but may be a mix of cases.
- **Pseudo-ops:** No pseudo-instructions (for example, `move`, `li` for 32-bit) are supported; all code must use the base instruction set.

### 3. Numeric Constants & Literals

- **Prefixes:** Hexadecimal uses `0x` (for example, `0x1F`); binary uses `0b` (for example, `0b101`).
- **Signedness:** A dash (`-`) denotes negative values (for example, `-7`).
- **Bit Limits:**
    - C-type (`CON`): 3 bits (Unsigned: 0 to 7; Signed: -4 to 3).
    - O-type (`OFF`): 6 bits (Signed: -32 to 31).
- **Extension:** The assembler handles sign or zero extension automatically based on the instruction requirements.

### 4. Formatting & Comments

- **Separators:** A single comma must separate operands. A single space must follow the mnemonic.
- **Memory Indirects:** Parentheses `(rB)` are for human readability only and are ignored by the assembler.
- **Comments:** The hash symbol (`#`) initiates a comment. All text between the `#` and the new line is ignored.

### 5. Control Flow & Addressing

- **Label Resolution:** Labels represent a specific 9-bit memory address.
- **Jump Calculations:** Jump instructions calculate a 6-bit signed offset relative to the incremented PC (`PC + 1`).
- **Offset Formula:** `OFF = Addr[LABEL] - (PC + 1)`.
