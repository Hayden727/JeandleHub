/*
 * @test TestGetstatic.java
 * @library /test/lib
 * @run main/othervm -XX:-TieredCompilation -Xcomp
 *      -XX:CompileCommand=compileonly,TestGetstatic::testGetstatic
 *      -XX:+UseC3Compiler TestGetstatic
 */

//  import jdk.test.lib.Asserts;

package compiler.jeandle.bytecodeTranslate;

 public class TestGetstatic {
     static int a = 1;
     static int b = 2;
     public static void main(String[] args) {
        int result = testGetstatic();
        System.out.println("Result of getstatic test: " + result);
        System.out.println("Expected: 3 (a + b = 1 + 2)");
        if (result == 3) {
            System.out.println("SUCCESS: getstatic support is working correctly!");
        } else {
            System.out.println("FAILURE: getstatic support is not working correctly!");
            System.exit(1);
        }
     }
 
     static int testGetstatic() {
         return a + b;
     }
 }
 