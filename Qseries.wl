(* ::Package:: *)

BeginPackage["QSeries`"];

(*Exported functions*)
aqprod::usage=
	"aqprod[a, q, n] computes the product (1 - a)(1 - aq)...(1 - aq^(n - 1)). Returns 1 if n = 0.";
etamake::usage = 
	"etamake[f, q, T] converts the q-series f into an eta-product expansion that agrees with f to O(q^T).";
etaq::usage = 
	"etaq[q, a, T] returns the q-series expansion to O(q^T) of the eta-product.";
qbin::usage = 
	"qbin[q, m, n] computes the q-binomial coefficient (n choose m) in terms of q, where:
  q: the base of the q-binomial,
  m: an integer (the lower bound of the binomial coefficient),
  n: an integer (the upper bound of the binomial coefficient).
  
The function returns the value of the q-binomial coefficient as the product of q terms, calculated using the formula:
  (1 - q)(1 - q^2)...(1 - q^n) / [(1 - q)(1 - q^2)...(1 - q^m)][(1 - q)(1 - q^2)...(1 - q^(n - m))].

If q is a symbol, the function returns the symbolic result, otherwise, it substitutes _x for q and calculates the result. 
If the inputs are not integers or are not in the valid range, it returns 0.";

findcong::usage = 
    "findcong[QS_, T_, LM_:Null, XSET_:{}] computes a set of congruence relations based on inputs:
    QS: a polynomial with variable q,
    T: a target integer,
    LM (optional): an upper bound for M (defaults to Floor[Sqrt[T]]),
    XSET (optional): a set of excluded integers.
    Returns a set of lists {r, M, P^R} where P^R is a prime power satisfying certain conditions.";
findcong::argerr = 
	"findcong takes 2, 3, or 4 arguments.";


Begin["`Private`"];

(*aqprod*)
(*
Takes in the inputs: 
a: any number
q: any number
n: non-negative integer
*)
(*
Gives the output:
if n = 0;
	1
if n not equal to 0;
	(1-a)(1-aq)...(1-aq^(n-1)) 
*)
aqprod[a_, q_, n_] := Module[{x = 1, i},
   If[IntegerQ[n] && n >= 0,
    (* Check if n is a non-negative integer *)
    Do[x = x*(1 - a*q^(i - 1)), {i, 1, n}],
    (* Product loop *)
    x = Subscript[{a, q}, n]]; (* Closing the If block properly *)
   Return[x];
];


(*etamake*)
(* Helper function to compute eta *)
eta[z_] := Product[1 - Exp[2 Pi I n z], {n, 1, Infinity}];

(* Helper function to compute eta(q) *)
etaq[q_, ld_, alast_] := Product[1 - q^n, {n, 1, ld}];

(* Main function *)
etamake[f_, q_, T_] := Module[
  {fp, tc, exq, g, aa, ld, h, hh, i, cf, etaprod, alast, sf},
  
  (* Expand the series *)
  sf = Series[f, {q, 0, T + 10}];  (* Expand to T + 10 to ensure accuracy *)
  fp = Normal[sf];                 (* Convert the series to polynomial *)
  
  (* Get coefficients *)
  tc = Coefficient[fp, q, 0];      (* Constant term *)
  exq = Exponent[fp, q];            (* Degree of q in fp *)
  g = Normal[fp/(tc*q^exq)];        (* Normalize the function *)
  aa = tc;                          (* Initialize aa *)
  ld = 1;                           (* Initialize ld *)
  alast = T - exq;                  (* Compute alast *)
  
  (* Loop to compute etaprod *)
  While[ld > 0,
    h = Series[g - 1, {q, 0, alast + 1}]; (* Series expansion *)
    hh = 0;
    
    (* Compute coefficients *)
    For[i = 0, i <= alast, i++,
      hh += Coefficient[h, q, i]*q^i;
    ];
    
    h = hh; (* Update h *)
    
    If[h === 0,
      ld = 0; (* Exit if h is zero *)
    ,
      ld = Exponent[h, q]; (* Get leading degree of h *)
    ];
    
    cf = Coefficient[h, q, ld]; (* Coefficient of leading degree *)
    
    If[ld > 0,
      exq += (1/24)*ld*cf; (* Update exq *)
      aa = eta[ld*tau]^(-cf)*aa; (* Update aa *)
      g *= etaq[q, ld, alast]^cf; (* Update g *)
    ];
  ];
  
  etaprod = q^exq*aa; (* Final product *)
  
  Return[etaprod]; (* Return result *)
];

(*etaq*)
etaq[q_, a_, T_] := Module[
  {k, x, z1, z, w, trunk},
  
  trunk = T;  (* Initialize trunk with the input T *)
  z1 = (1/6)*(a + Sqrt[a^2 + 24*trunk*a])/a;  (* Compute z1 *)
  z = Floor[1 + N[z1]];  (* Compute z and round down *)
  x = 0;  (* Initialize x *)
  
  (* Loop to compute the eta product *)
  For[k = -z, k <= z, k++,
    w = (1/2)*a*k*(3*k - 1);  (* Compute w based on k *)
    If[w <= trunk && w >= 0,  (* Check if w is within the trunk *)
      x += q^w*(-1)^k;  (* Update x with the series terms *)
    ];
  ];
  
  (* Expand the result up to O(q^T) *)
  Return[Series[x, {q, 0, T}]];  (* Return the computed series up to O(q^T) *)
];

(*qbin*)
qbin[q_, m_, n_] := 
  If[IntegerQ[m] && IntegerQ[n], (* Check if m and n are integers *)
    If[0 <= m <= n, (* Check if m is between 0 and n *)
        Return[Normal[aqprod[q, q, n]/(aqprod[q, q, m]*aqprod[q, q, n - m])]//FullSimplify],
      Return[0] (* Return 0 if m is not in range *)
    ],
    (* If m or n are not integers, throw an error *)
    Message[qbin::argerr, m, n]
  ]
qbin::argerr = "m and n must be integers.";



End[];
EndPackage[];

