From Ssreflect
     Require Import ssreflect ssrbool eqtype ssrnat seq tuple fintype ssrfun div.
From Bits
     Require Import bits.
Require Import specs props off_r.

Lemma count_off_r:
  forall n (bs: BITS n), bs <> #0 ->
    count_mem true (andB bs (subB bs #1)) = (count_mem true bs) - 1.
Proof.
  move=> n bs bs_neqz.
  rewrite off_r_repr.
  elim: n bs bs_neqz=> [bs|n IHn bs] bs_neqz.
  + (* Case: n ~ 0 *)
    exfalso.
    apply bs_neqz.
    by apply trivialBits.
  + (* Case: n ~ n + 1 *)
    case/tupleP: bs bs_neqz=>b bs bs_neqz.
    case: b bs_neqz=> bs_neqz.
    - (* Case: b ~ true *)
      have ->: off_r [tuple of true :: bs] = [tuple of false :: bs]
        by apply: val_inj.
      rewrite /=.
      auto with arith.
    - (* Case: b ~ false *)
      have ->: off_r [tuple of false :: bs] = [tuple of false :: (off_r bs)]
        by apply: val_inj.
      rewrite /=.
      apply IHn.
      move=> bs_eqz.
      apply bs_neqz.
      rewrite bs_eqz //.
Qed.

(*
Definition pop {n}(bs: BITS n): nat
  := let fix count n x :=
       if x == #0 then n
       else count (n + 1) (andB x (subB x #1))
     in count 0 bs.

Lemma pop_repr:
  forall n (bs: BITS n),
    pop bs = count_bits bs true.
Proof.
  admit.
Admitted.
*)
(*
Definition pop_mask_seq {n}(k: nat): seq bool
  := let fix aux n (k: 'I_k) b :=
       match n with
       | 0 => [::]
       | n'.+1 =>
         let b' := (if k == 0 then ~~ b else b) in
         cons b' (aux n' k.+1 b')
       end
     in aux n 0 false.

  match xs with
    | [::] => [::]
    | cons false xs => cons false (off_r_seq xs)
    | cons true xs => cons false xs
  end.
*)

Definition pop_mask_seq {n}(k: nat): seq bool
  := let fix aux n :=
       match n with
       | 0 => [::]
       | n'.+1 => ((n' %% (2 * k)) >= k) :: aux n'
       end
     in aux n.

Lemma pop_maskP {n}(k: nat): size (pop_mask_seq (n := n) k) == n.
Proof.
  elim: n=> [|n IHn] //=.
Qed.

Canonical pop_mask {n} (k: nat): BITS n
  := Tuple (pop_maskP k).

Definition pop_nextBits {n}(bs: BITS (2^n))(k: nat) : BITS (2^n) :=
   addB (andB bs (pop_mask k)) (andB (shrBn bs k) (pop_mask k)).

Fixpoint popAux {n}(i: nat)(k: nat)(x: BITS (2^n)): BITS (2^n)
  := match i with
     | 0 => x
     | i'.+1 => popAux i' k.*2 (pop_nextBits x k)
     end.

Definition pop {n}(bs: BITS (2^n)): nat
  := toNat(popAux n 1 bs).

Fixpoint sum_tuple_seq {n}(bs: BITS n)(k: nat): seq nat
  := let fix aux n k x: seq nat :=
       match n with
       | 0 => map (fun b => (if b then 1 else 0)) bs
       | n'.+1 => let t' := aux n' (k./2) x in
                  mkseq (fun i => nth 0 t' (2 * i) + nth 0 t' (2 * i + 1)) (n %/ k)
       end
     in aux n k bs.

Lemma sum_tupleP {n}(bs: BITS n)(k: nat):
  size (sum_tuple_seq bs k) == n %/ k.
Proof.
  case: n bs=> [|n] bs.
  + (* n ~ 0 *)
    rewrite tuple0 div0n //.
  + (* n ~ n.+1 *)
    by rewrite size_mkseq //.
Qed.

Canonical sum_tuple {n}(bs: BITS n)(k: nat): (n %/ k).-tuple nat
  := Tuple (sum_tupleP bs k).

(*
 * sumn (sum_tuple (addB (andB x (pop_mask k)) (andB (shrBn x k) (pop_mask k))) k.*2)
 * (= sumn (sum_tuple f(x) k.*2))
 * = sumn (sum_tuple x k)

   sum_tuple x k [i.*2] + sum_tuple x k [i.*2 + 1]
   = sum_tuple f(x) k.*2 [i]

 * 1) Show that sum_tuple x k [i] = toNat (take k (shrB (k*i) x))
 * 2) Show that:
   toNat (take k (shrBn (k*i.*2) x)) + toNat (take k (shrBn (k*i.*2 + k) x)) (X)
   = toNat (take k.*2 (shrBn (k*i.*2) f(x)))

   Because (addB (take k bs) (take k bs')) = take k.*2 (addB bs bs'):
   X = toNat (take k.*2 (addB (shrBn (k*i.*2) x) (shrBn (k*i.*2 + k) x)))

   And:
   take k.*2 (shrBn (k*i.*2) (addB (andB x (pop_mask k)) (andB (shrBn x k) (pop_mask k)))
   = take k.*2 (addB (shrBn (k*i.*2) x) (shrBn (k*i.*2 + k) x))

   => sumn (sum_tuple bs 1) = sumn (sum_tuple (popAux n 1 bs) (2^n))
      = count_mem true bs     = pop bs
*)

Lemma pop_repr:
  forall n (bs: BITS (2 ^ n)),
    pop bs = count_mem true bs.
Proof.
  move=> n bs.
  have ->: pop bs = sumn (sum_tuple (popAux n 1 bs) n)
    by admit.
  have ->: count_mem true bs = sumn (sum_tuple bs 1)
    by admit.
  have: forall x k, sumn (sum_tuple x k) = sumn (sum_tuple bs 1)
    -> sumn (sum_tuple (pop_nextBits x k) k.*2) = sumn (sum_tuple bs 1).
    admit.
    rewrite /popAux.
  admit.
Admitted.