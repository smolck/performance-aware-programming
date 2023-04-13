package sim8086

import "core:fmt"
import "core:os"

Register :: enum {
    // 8 bit, 16 bit
    AL, AX,
    CL, CX,
    DL, DX,
    BL, BX,
    AH, SP,
    CH, BP,
    DH, SI,
    BH, DI,
}

Opcode_Ty :: enum {MovR}

Op :: struct {
    t: Opcode_Ty,
    // reg_field_specifies: enum{Src, Dest},
    src: Register,
    dest: Register,
}

register_for :: proc(r: u8, wide: bool) -> Register {
    switch (r) {
    case 0b000:
        return wide ? Register.AX : Register.AL
    case 0b001:
        return wide ? Register.CX : Register.CL
    case 0b010:
        return wide ? Register.DX : Register.DL
    case 0b011:
        return wide ? Register.BX : Register.BL
    case 0b100:
        return wide ? Register.SP : Register.AH
    case 0b101:
        return wide ? Register.BP : Register.CH
    case 0b110:
        return wide ? Register.SI : Register.DH
    case 0b111:
        return wide ? Register.DI : Register.BH
    }

    return nil
}

op_for :: proc(b: byte, b2: byte) -> Op {
    t: Opcode_Ty

    switch (b >> 2) { // >> 2 cuz we only care about first 6 bits
    case 0b100010:
        t = Opcode_Ty.MovR
    case:
        panic("Unhandled opcode")
    }

    reg1_is_destination := ((b >> 1) & 1) == 1
    wide := (b & 1) == 1 // true if 16-bit

    // Ignore MOD for now, should just be operating on registers
    assert(((b2 >> 7) & 1) == 1)
    assert(((b2 >> 6) & 1) == 1)

    reg1_b := (b2 << 2) >> 5 // Get first register which are bits 3-5 
    reg2_b := b2 & 0x7 // Get second register which is the last 3 bits

    reg1 := register_for(reg1_b, wide)
    reg2 := register_for(reg2_b, wide)

    src : Register
    dest : Register

    if reg1_is_destination {
        src = reg2
        dest = reg1
    } else {
        src = reg1
        dest = reg2
    }

    return Op{t, src, dest}
}

main :: proc() {
    data, _ := os.read_entire_file(os.args[1])
    defer delete(data)

    for i := 0; i < len(data); i += 2 {
        fmt.println(op_for(data[i], data[i + 1]))
    }
}
