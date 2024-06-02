Inductive AExp : Type :=
| ALit (n : nat)
| APlus (a1 a2 : AExp)
| ASub (a1 a2 : AExp)
.

Fixpoint aeval (a : AExp) : nat :=
match a with
 | ALit n => n
 | APlus a1 a2 => aeval a1 + aeval a2
 | ASub a1 a2 => aeval a1 - aeval a2
end.

Require Import Coq.Arith.Plus.

Fixpoint optim' (a : AExp) : AExp :=
  match a with
  | ALit n => ALit n
  | APlus (ALit x) (ALit y) => ALit (x + y)
  | APlus e1 e2 => APlus (optim' e1) (optim' e2)
  | ASub  e1 e2 => ASub  (optim' e1) (optim' e2)
  end.

Lemma optim'_sound (a : AExp) : aeval (optim' a) = aeval a.
Proof. induction a.
Admitted.

(* bevezetjuk a valtozokat *)

Require Import Strings.String.

(* lecsereljuk AExp-et erre: *)
Inductive exp : Type :=
  | lit : nat -> exp
  | var : string -> exp
  | sub : exp -> exp -> exp
  | plus : exp -> exp -> exp.

Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

(*
e :=
   +
  / \
  W  3
*)

Definition e : exp := lit 0. (* javitsd ki, hogy ugy nezzen ki, mint a rajz! *)

(*
e' :=
   +
  / \
  W  -
    / \
   Z   1
*)

Definition e' : exp := lit 0.
(* javitsd ki, hogy ugy nezzen ki, mint a rajz! *)

Definition state : Type := string -> nat.

Fixpoint eval (e : exp)(s : state) : nat :=
  match e with
  | lit n => n
  | var x => s x
  | sub e1 e2 => eval e1 s - eval e2 s
  | plus e1 e2 => eval e1 s + eval e2 s
  end.

Definition empty : state := fun x => 0.

Compute eval e' empty.
Compute eval e' (fun x => 2).

Definition update (x : string)(n : nat)(s : state)
  : state := fun x' => match string_dec x x' with
  | left e  => n
  | right ne => s x'
  end.

Check string_dec.

(* W|-> 3, X|->5, Y,Z|->0 *)
Definition exState : state := update W 3 (update X 5 empty).

Definition st : state := empty. (* <- change this so that you can prove e'val! *)

Lemma e'val : eval e' st = 3.
Admitted.

Definition e'' : exp := var W. (* <- change this so that you can prove e''indep! *)

Lemma e''indep : forall (s s' : state), eval e'' s = eval e'' s'.
Admitted.

Definition e''' : exp := var X. (* valami mas! *)

(*  (X |-> 3, Y |-> 4, Z |-> 22, ... |-> 0) *)
(*  (X |-> 2, Y |-> 4, Z |-> 22, ... |-> 0) *)

Lemma e'''notIndep : ~ (forall (s s' : state),
   eval e''' s = eval e''' s').
Admitted.

Lemma update_sound (x : string)(n : nat)(s : state) :
  (update x n s) x = n.
Admitted.

Lemma update_neq (x x' : string)(n : nat)(s : state)
  (ne : x <> x') :
  (update x n s) x' = s x'.
Admitted.

Fixpoint emb (a : AExp) : exp := match a with
  | ALit n => lit n
  | ASub  a1 a2 => sub (emb a1) (emb a2)
  | APlus a1 a2 => plus (emb a1) (emb a2)
  end.

Lemma closed_state (a : AExp)(s s' : state) : 
  eval (emb a) s = eval (emb a) s'.
Admitted.