From Coq Require Import Strings.String.
From Coq Require Import Bool.Bool.
From Coq Require Import Init.Nat.

Inductive aexp : Type :=
  | alit (n : nat)
  | avar (x : string)
  | aplus (a1 a2 : aexp)
  | aminus (a1 a2 : aexp)
  | amult (a1 a2 : aexp).

Inductive bexp : Type :=
| btrue
| bfalse
| band (b1 b2 : bexp)
| bnot (b : bexp)
| beq (a1 a2 : aexp)
| bleq (a1 a2 : aexp).

Inductive cmd : Type :=
| cskip
| cif (b : bexp) (c1 c2 : cmd)
| cwhile (b : bexp) (c : cmd)
| cassign (x : string) (a : aexp)
| cseq (c1 c2 : cmd)
(* FOR X FROM 1 TO 10 DO Y ::= Y + X END *)
| cfor (x : string)(a1 a2 : aexp)(c : cmd).

Coercion avar : string >-> aexp.
Coercion alit : nat >-> aexp.
Notation "x + y"     := (aplus x y) (at level 50, left associativity).
Notation "x - y"     := (aminus x y) (at level 50, left associativity).
Notation "x * y"     := (amult x y) (at level 40, left associativity).
Definition bool2bexp (b : bool) : bexp := if b then btrue else bfalse.
Coercion bool2bexp : bool >-> bexp.
Notation "x & y" := (band x y) (at level 81, left associativity).
Notation "'~' b" := (bnot b) (at level 75, right associativity).
Notation "x == y" := (beq x y) (at level 70, no associativity).
Notation "x <= y" := (bleq x y) (at level 70, no associativity).
Notation "'SKIP'"    := cskip.
Notation "'TEST' b 'THEN' c1 'ELSE' c2 'FI'" := (cif b c1 c2) (at level 80, right associativity).
Notation "'WHILE' b 'DO' c 'END'" := (cwhile b c) (at level 80, right associativity).
Notation "x '::=' a" := (cassign x a) (at level 60).
Notation "c1 ;; c2"  := (cseq c1 c2) (at level 80, right associativity).
Notation "'FOR' x 'FROM' a1 'TO' a2 'DO' c 'END'" := (cfor x a1 a2 c) (at level 80, right associativity).

Definition X : string := "X"%string.
Definition Y : string := "Y"%string.
Definition Z : string := "Z"%string.



Definition state : Type := string -> nat.

Definition empty : state := fun x => 0.

Definition update (x:string)(n:nat)(s:state) : state :=
  fun x' => match string_dec x x' with
  | left  e => n
  | right e => s x'
  end.

Fixpoint aeval (a : aexp)(s : state) : nat :=
match a with
| alit n => n
| avar x => s x
| aplus a1 a2 => (aeval a1 s) + (aeval a2 s)
| aminus a1 a2 => (aeval a1 s) - (aeval a2 s)
| amult a1 a2 => (aeval a1 s) * (aeval a2 s)
end.

Fixpoint beval (b : bexp)(s : state) : bool :=
match b with
 | btrue => true
 | bfalse => false
 | band b1 b2 => (beval b1 s) && (beval b2 s)
 | bnot b => negb (beval b s)
 | beq a1 a2 => aeval a1 s =? aeval a2 s
 | bleq a1 a2 => aeval a1 s <=? aeval a2 s
end.

(*
Fixpoint iseven (n : nat) : bool := match n with
  | O => true
  | S n' => negb (isodd n')
  end
with isodd (n : nat) : bool := match n with
  | O => false
  | S n' => negb (iseven n')
  end.
*)
Fixpoint isevenif (b : bool)(n : nat) : bool := if b
  then
    match n with
    | O => true
    | S n' => negb (isevenif false n')
    end
  else
    match n with
    | O => false
    | S n' => negb (isevenif true n')
    end.

Definition iseven (n : nat) : bool := isevenif true  n.
Definition isodd  (n : nat) : bool := isevenif false n.

Fixpoint ceval (c : cmd)(s : state)(n : nat) : state := match n with
  | O => s
  | S n' => match c with
    | cskip       => s
    | cif b c1 c2 => if beval b s then ceval c1 s n' else ceval c2 s n'
    | cwhile b c  => if beval b s then ceval (cwhile b c) (ceval c s n') n' else s
    | cassign x a => update x (aeval a s) s
    | cseq c1 c2  => ceval c2 (ceval c1 s n') n'
    | FOR x FROM a1 TO a2 DO c END => let s' := update x (aeval a1 s) s in
        foreval x a2 c s' n'
    end
  end
with
foreval (x : string)(a2 : aexp)(c : cmd)(s : state)(n : nat) : state := match n with
  | O => s
  | S n' =>
    if s x <=? aeval a2 s
    then
      let s' := ceval c s n' in
      foreval x a2 c (update x (s' x + 1) s') n'
    else s
  end.

Definition prog := FOR X FROM 1 TO 10 DO Y ::= Y + X END.

Compute ceval prog empty 20 Y.

Reserved Notation "| s , st |=> st'" (at level 50).
Inductive cevalb : cmd -> state -> state -> Prop :=

  | cevalb_skip (s : state) :

       (*------------*)
       | SKIP , s |=> s

  | cevalb_assign (x : string)(a : aexp)(s : state) :

       (*------------------------------------*)
       | x ::= a , s |=> update x (aeval a s) s

  | cevalb_seq (c1 c2 : cmd)(s s' s'' : state) : 

       | c1 , s |=> s'  ->  | c2 , s' |=> s''  ->
       (*------------------------------------*)
              | c1 ;; c2 , s |=> s''

  | cevalb_if_true (b : bexp)(c1 c2 : cmd)(s s' : state) :

       beval b s = true -> | c1 , s |=> s' ->
       (*------------------------------------*)
       | TEST b THEN c1 ELSE c2 FI , s |=> s'

  | cevalb_if_false (b : bexp)(c1 c2 : cmd)(s s' : state) :

       beval b s = false -> | c2 , s |=> s' ->
       (*------------------------------------*)
       | TEST b THEN c1 ELSE c2 FI , s |=> s'

  | cevalb_while_false (b : bexp)(c : cmd)(s : state) :

           beval b s = false       ->
       (*------------------------*)
       | WHILE b DO c END , s |=> s

  | cevalb_while_true (b : bexp)(c : cmd)(s s' s'' : state) :

       beval b s = true                  ->
       | c , s |=> s'                    ->
       | WHILE b DO c END , s' |=> s''   ->
       (*---------------------------*)
       | WHILE b DO c END , s |=> s''

  | cevalb_for (x : string)(a1 a2 : aexp)(c : cmd)(s s' : state) :

       forevalb x a2 c (update x (aeval a1 s) s) s' ->
       (*---------------------------------------*)
       | FOR x FROM a1 TO a2 DO c END , s |=> s'

where "| c , s |=> s'" := (cevalb c s s')
with
forevalb : string -> aexp -> cmd -> state -> state -> Prop :=
  | forevalb_end (x : string)(a2 : aexp)(c : cmd)(s : state) : 

       (s x <=? aeval a2 s) = false     ->
       (*----------------------------*)
       forevalb x a2 c s s

  | forevalb_step (x : string)(a2 : aexp)(c : cmd)(s s' s'' : state) : 

       (s x <=? aeval a2 s) = true     ->
       | c , s |=> s'                 ->
       forevalb x a2 c (update x (s' x + 1) s') s'' ->
       (*-----------------------------------------*)
       forevalb x a2 c s s''.

Example l1 : | FOR X FROM 1 TO 1 DO Y ::= Y + 5 END , empty |=>
  update X 2 (update Y 5 (update X 1 empty)).
apply cevalb_for. simpl.
apply forevalb_step with (s' := update Y 5 (update X 1 empty)).
- simpl. reflexivity.
- apply cevalb_assign.
- simpl. apply forevalb_end. simpl. reflexivity.
Qed.

Definition cfor1 (x : string)(a1 a2 : aexp)(c : cmd) : cmd :=
  x ::= a1 ;;
  WHILE x <= a2 DO
    c ;;
    x ::= x + 1
  END.

Notation "'FOR1' x 'FROM' a1 'TO' a2 'DO' c 'END'" := (cfor1 x a1 a2 c) (at level 80, right associativity).

Lemma forl (x : string)(a1 a2 : aexp)(c : cmd)(s s' : state) :
  | FOR  x FROM a1 TO a2 DO c END , s |=> s' <->
  | FOR1 x FROM a1 TO a2 DO c END , s |=> s'.
split. Focus 2.
- intro. unfold cfor1 in H. apply cevalb_for. inversion H. inversion H2.
  rewrite <- H9 in H5.



Lemma determ_bigstep (s s1 : state)(c : cmd) :
  | c , s |=> s1 -> forall (s2 : state), | c , s |=> s2 -> s1 = s2.
intro. induction H; intros.
- inversion H. reflexivity.
- inversion H. reflexivity.
- inversion H1. rewrite <- (IHcevalb1 _ H4) in H7. apply IHcevalb2. exact H7.
- inversion H1.
-- apply IHcevalb. exact H8.
-- rewrite -> H in H7. discriminate H7.
- inversion H1.
-- rewrite -> H in H7. discriminate H7.
-- apply IHcevalb. exact H8.
- inversion H0.
-- reflexivity.
-- rewrite -> H in H3. discriminate H3.
- inversion H2.
-- rewrite <- H6 in H7. rewrite -> H in H7. discriminate H7.
-- rewrite <- (IHcevalb1 _ H6) in H9. apply IHcevalb2. exact H9.
Qed.
(*
Inductive E : Type :=
  | step : E -> E.

Lemma noE : ~ E.
intro. induction H. exact IHE.
Qed.

Require Import Coq.Program.Equality.

Definition inf := WHILE true DO SKIP END.

Lemma noInf (s : state) : ~ exists s', | inf , s |=> s'.

Definition Equiv0 (c1 c2 : cmd) : Prop := forall s,
  exists s1 s2, | c1 , s |=> s1 /\ | c2 , s |=> s2 /\ forall x, s1 x = s2 x.

Lemma eq3 : ~ forall c, Equiv0 c c.

Lemma eq3 : ~ forall c, Equiv0 (SKIP ;; c) c.
*)
Definition Equiv1 (c1 c2 : cmd) : Prop := forall s,
  ((exists s1, | c1 , s |=> s1) <-> (exists s2, | c2 , s |=> s2)) /\ 
  (forall s1 s2, | c1 , s |=> s1 /\ | c2 , s |=> s2 -> forall x, s1 x = s2 x).

Lemma eq4 (c : cmd) : Equiv1 (SKIP ;; c) c.
intro. split.
- unfold iff. split; intro; destruct H as [s' H]; exists s'.
-- inversion H. inversion H2. exact H5.
-- apply cevalb_seq with (s' := s).
--- apply cevalb_skip.
--- exact H.
- intros. destruct H. inversion H. inversion H3. rewrite <- H9 in H6.
rewrite -> (determ_bigstep _ _ _ H6 _ H0). reflexivity.
Qed.

Lemma eq5 : Equiv1 SKIP (WHILE false DO X ::= Y END).
intro. split.
- split; intro; destruct H as [s' H]; exists s.
-- apply cevalb_while_false. reflexivity.
-- apply cevalb_skip.
- intros. destruct H. inversion H. rewrite <- H3. inversion H0.
-- reflexivity.
-- simpl in H5. discriminate H5.
Qed.

Lemma eq6 (a : aexp) : ~ Equiv1 (X ::= a) (X ::= 0 ;; X ::= a).

Lemma eq7 : Equiv1 inf (WHILE true DO X ::= X + 1 END).