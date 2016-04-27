open Printf

type reg =
  | EAX
  | EBX
  | ECX
  | EDX
  | ESP
  | EBP
  | EDI
  | ESI

type size =
  | DWORD_PTR
  | WORD_PTR
  | BYTE_PTR

type arg =
  | Const of int
  | HexConst of int
  | Reg of reg
  | RegOffset of int * reg
  | RegOffsetReg of reg * reg * int * int
  | Sized of size * arg

type instruction =
  | IMov of arg * arg

  | IAdd of arg * arg
  | ISub of arg * arg
  | IMul of arg * arg

  | IShr of arg * arg
  | IShl of arg * arg

  | IAnd of arg * arg
  | IOr of arg * arg
  | IXor of arg * arg

  | ILabel of string
  | IPush of arg
  | IPop of arg
  | ICall of string
  | IRet

  | ICmp of arg * arg
  | IJne of string
  | IJe of string
  | IJg of string
  | IJge of string
  | IJl of string
  | IJmp of string
  | IJno of string
  | IJo of string

let r_to_asm (r : reg) : string =
  match r with
    | EAX -> "eax"
    | EBX -> "ebx"
    | ECX -> "ecx"
    | EDX -> "edx"
    | ESP -> "esp"
    | EBP -> "ebp"
    | EDI -> "edi"
    | ESI -> "esi"

let s_to_asm (s : size) : string =
  match s with
    | DWORD_PTR -> "DWORD"
    | WORD_PTR -> "WORD"
    | BYTE_PTR -> "BYTE"

let rec arg_to_asm (a : arg) : string =
  match a with
    | Const(n) -> sprintf "%d" n
    | HexConst(n) -> sprintf "0x%X" n
    | Reg(r) -> r_to_asm r
    | RegOffset(n, r) ->
      if n >= 0 then
        sprintf "[%s+%d]" (r_to_asm r) n
      else
        sprintf "[%s-%d]" (r_to_asm r) (-1 * n)
    | RegOffsetReg(r1, r2, mul, off) ->
      sprintf "[%s + %s * %d + %d]"
        (r_to_asm r1) (r_to_asm r2) mul off
    | Sized(s, a) ->
      sprintf "%s %s" (s_to_asm s) (arg_to_asm a)

let i_to_asm (i : instruction) : string =
  match i with
    | IMov(dest, value) ->
      sprintf "  mov %s, %s" (arg_to_asm dest) (arg_to_asm value)
    | IAdd(dest, to_add) ->
      sprintf "  add %s, %s" (arg_to_asm dest) (arg_to_asm to_add)
    | ISub(dest, to_sub) ->
      sprintf "  sub %s, %s" (arg_to_asm dest) (arg_to_asm to_sub)
    | IMul(dest, to_mul) ->
      sprintf "  imul %s, %s" (arg_to_asm dest) (arg_to_asm to_mul)
    | IAnd(dest, mask) ->
      sprintf "  and %s, %s" (arg_to_asm dest) (arg_to_asm mask)
    | IOr(dest, mask) ->
      sprintf "  or %s, %s" (arg_to_asm dest) (arg_to_asm mask)
    | IXor(dest, mask) ->
      sprintf "  xor %s, %s" (arg_to_asm dest) (arg_to_asm mask)
    | IShr(dest, to_shift) ->
      sprintf "  shr %s, %s" (arg_to_asm dest) (arg_to_asm to_shift)
    | IShl(dest, to_shift) ->
      sprintf "  shl %s, %s" (arg_to_asm dest) (arg_to_asm to_shift)
    | ICmp(left, right) ->
      sprintf "  cmp %s, %s" (arg_to_asm left) (arg_to_asm right)
    | IPush(arg) ->
      sprintf "  push %s" (arg_to_asm arg)
    | IPop(arg) ->
      sprintf "  pop %s" (arg_to_asm arg)
    | ICall(str) ->
      sprintf "  call %s" str
    | ILabel(name) ->
      sprintf "%s:" name
    | IJne(label) ->
      sprintf "  jne near %s" label
    | IJe(label) ->
      sprintf "  je near %s" label
    | IJl(label) ->
      sprintf "  jl near %s" label
    | IJg(label) ->
      sprintf "  jg near %s" label
    | IJge(label) ->
      sprintf "  jge near %s" label
    | IJno(label) ->
      sprintf "  jno near %s" label
    | IJo(label) ->
      sprintf "  jo near %s" label
    | IJmp(label) ->
      sprintf "  jmp near %s" label
    | IRet ->
      "  ret"

let to_asm (is : instruction list) : string =
  List.fold_left (fun s i -> sprintf "%s\n%s" s (i_to_asm i)) "" is

