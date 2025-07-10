 /*
 * @test TestStaticFieldAccess.java
 * @library /test/lib
 * @run main/othervm -XX:-TieredCompilation -Xcomp
 *      -XX:CompileCommand=compileonly,TestStaticFieldAccess::testStaticFields
 *      -XX:+UseJeandleCompiler TestStaticFieldAccess
 */

// package compiler.jeandle.bytecodeTranslate;

 public class TestStaticFieldAccess {
    static int sa = 10;
    static int sb = 20;

    // Only perform static field operations, no new
    static int testStaticFields() {
        sb = 22; // putstatic
        int sum = sa + sb; // getstatic
        return sum;
    }

    // Only perform instance field operations (no new, only operate on parameter object)
    static int testInstanceFieldOps(MyClass a) {
        a.field = 200; // putfield
        int val = a.field; // getfield
        return val;
    }

    public static void main(String[] args) throws Exception {
        int staticCode = testStaticFields();
        System.out.println(staticCode); // Only print in main
        if (staticCode == 32) {
            System.out.println("SUCCESS: Static field access is working correctly!");
        } else {
            System.out.println("FAILURE: Static field access is not working correctly! staticCode=" + staticCode);
        }
        // Test instance field operations
        MyClass obj = new MyClass();
        int instanceCode = testInstanceFieldOps(obj);
        System.out.println(instanceCode); // Only print in main
        if (instanceCode == 200) {
            System.out.println("SUCCESS: Instance field access is working correctly!");
        } else {
            System.out.println("FAILURE: Instance field access is not working correctly! instanceCode=" + instanceCode);
        }
    }
}

class MyClass {
    public int field = 100;
}
