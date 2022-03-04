public class TestPortal {

    // enable this to make pretty printing a bit more compact
    private static final boolean COMPACT_OBJECTS = false;

    // This class creates a portal connection and runs a few tests
    public static void main(String[] args) {
        try {
            PortalConnection c = new PortalConnection();
            // Test 1. List info for a student.
            prettyPrint(c.getInfo("4444444444"));
            pause();

            // Test 2. Register a student for an unrestricted course.
            System.out.println(c.register("4444444444", "UNREST"));
            prettyPrint(c.getInfo("4444444444")); // UNREST should be listed
            pause();

            // Test 3. Register the above student again, we should get an error.
            System.out.println(c.register("4444444444", "UNREST"));
            pause();

            // Test 4. Unregister the student twice. Second should throw an error.
            System.out.println(c.unregister("4444444444", "UNREST"));
            prettyPrint(c.getInfo("4444444444")); // UNREST should not be listed
            System.out.println(c.unregister("4444444444", "UNREST"));
            pause();

            // Test 5. Register the student to a course without prerequisites met. 
            // We expect an error here.
            System.out.println(c.register("4444444444", "NONPRE"));
            pause();

            // Test 6. Unregister a student from a limited course with two people in the
            // queue.
            System.out.println(c.register("0101010101", "TESTLI"));
            System.out.println(c.register("9999999999", "TESTLI"));
            System.out.println(c.register("8888888888", "TESTLI"));
            System.out.println(c.unregister("0101010101", "TESTLI"));
            System.out.println(c.register("0101010101", "TESTLI"));
            prettyPrint(c.getInfo("0101010101")); // position should be last (2)
            pause();

            // Test 7. Unregister and re-register the same student for the same restricted
            // course
            System.out.println(c.unregister("0101010101", "TESTLI"));
            System.out.println(c.register("0101010101", "TESTLI"));
            prettyPrint(c.getInfo("0101010101")); // position should be last
            pause();

            // Test 8. Unregister from an overfull course, no student should be moved to the
            // queue.
            System.out.println(c.unregister("0101010101", "FULLLL"));
            prettyPrint(c.getInfo("0101010101"));
            c.printWaitingList("FULLLL"); // should be empty
            pause();
            
            // Test 9. Use SQL injection to unregister all students.
            System.out.println(c.unregister("2222222222", "CCC333'; DELETE FROM Registrations;--"));


        } catch (ClassNotFoundException e) {
            System.err.println(
                    "ERROR!\nYou do not have the Postgres JDBC driver (e.g. postgresql-42.2.18.jar) in your runtime classpath!");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void pause() throws Exception {
        System.out.println("PRESS ENTER");
        while (System.in.read() != '\n')
            ;
    }

    // This is a truly horrible and bug-riddled hack for printing JSON.
    // It is used only to avoid relying on additional libraries.
    // If you are a student, please avert your eyes.
    public static void prettyPrint(String json) {
        System.out.print("Raw JSON:");
        System.out.println(json);
        System.out.println("Pretty-printed (possibly broken):");

        int indent = 0;
        json = json.replaceAll("\\r?\\n", " ");
        json = json.replaceAll(" +", " "); // This might change JSON string values :(
        json = json.replaceAll(" *, *", ","); // So can this

        for (char c : json.toCharArray()) {
            if (c == '}' || c == ']') {
                indent -= 2;
                breakline(indent); // This will break string values with } and ]
            }

            System.out.print(c);

            if (c == '[' || c == '{') {
                indent += 2;
                breakline(indent);
            } else if (c == ',' && !COMPACT_OBJECTS)
                breakline(indent);
        }

        System.out.println();
    }

    public static void breakline(int indent) {
        System.out.println();
        for (int i = 0; i < indent; i++)
            System.out.print(" ");
    }
}