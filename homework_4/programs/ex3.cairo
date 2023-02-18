// Perform and log output of simple arithmetic operations
func simple_math() {
   // adding 13 +  14
   let a = 13 + 14;

   // multiplying 3 * 6
   let b = 3 * 6;

   // dividing 6 by 2
   let c = 6 / 2;

   // dividing 70 by 2
   let d = 70 / 2;

   // dividing 7 by 2
   let e = 7 / 2;

    %{
        print(
            ids.a,
            ids.b,
            ids.c,
            ids.d,
            ids.e
        )
    %}

    return ();
}
