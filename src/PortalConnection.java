
import java.sql.*; // JDBC stuff.
import java.util.ArrayList;
import java.util.Properties;
import java.util.List;

import com.google.gson.JsonObject;
import com.google.gson.Gson;

public class PortalConnection {

    // Set this to e.g. "portal" if you have created a database named portal
    // Leave it blank to use the default database of your database user
    static final String DBNAME = "lab4";
    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/" + DBNAME;
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }

    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode) {
        try (PreparedStatement s = conn.prepareStatement("INSERT INTO Registrations VALUES(?,?);")) {
            s.setString(1, student);
            s.setString(2, courseCode);
            s.executeUpdate();
        } catch (SQLException e) {
            return new JsonResponse(false, e).getJson();
        }
        return new JsonResponse(true, null).getJson();
    }

    // Unregister a student from a course, returns a tiny JSON document (as a
    // String)
    public String unregister(String student, String courseCode) {
        String sql = "DELETE FROM Registrations WHERE student='"+student+"' AND course='" +courseCode+"';"; //deliberate Sql injection vulnerability
        try (Statement s = conn.createStatement()) {
            int del = s.executeUpdate(sql);
            if (del == 0)
                throw new SQLException("ERROR: Cannot unregister from course " + courseCode + " because student isn't registered in it.");
        } catch (SQLException e) {
            return new JsonResponse(false, e).getJson();
        }
        return new JsonResponse(true, null).getJson();
    }

    public void printWaitingList(String courseCode) {
        try (PreparedStatement s = conn.prepareStatement("SELECT * FROM CourseQueuePositions WHERE course=?")) {
            s.setString(1, courseCode);
            ResultSet rs = s.executeQuery();
            System.out.println("WaitingList:");
            while (rs.next())
                System.out.println(String.format("Course: %s    Student: %s     Position: %d", rs.getString("course"),
                        rs.getString("student"), rs.getInt("place")));
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    // Return a JSON document containing lots of information about a student, it
    // should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException {
        JsonObject info = new JsonObject();
        try (PreparedStatement st = conn
                .prepareStatement("SELECT idnr, login, name, program FROM BasicInformation WHERE idnr=?;")) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();

            if (rs.next()) {
                info.addProperty("student", rs.getString("idnr"));
                info.addProperty("name", rs.getString("name"));
                info.addProperty("login", rs.getString("login"));
                info.addProperty("program", rs.getString("program"));
            } else {
                // return new JsonRespons(false, new SQLException("Student does not
                // exist")).getJson();
                return "{\"student\":\"does not exist :(\"}";
            }
        }

        try (PreparedStatement st = conn.prepareStatement("SELECT branch FROM StudentBranches WHERE student=?;")) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();

            if (rs.next())
                info.addProperty("branch", rs.getString("branch"));
            else
                info.addProperty("branch", "No branch chosen");
        }

        try (PreparedStatement st = conn.prepareStatement(
                "SELECT course, name, status, place FROM Registrations JOIN Courses ON Registrations.course=Courses.code NATURAL LEFT JOIN CourseQueuePositions WHERE student=?;")) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();
            List<JsonObject> registeredCourses = new ArrayList<>();

            while (rs.next()) {
                JsonObject course = new JsonObject();
                course.addProperty("course", rs.getString("name"));
                course.addProperty("code", rs.getString("course"));
                course.addProperty("status", rs.getString("status"));
                course.addProperty("position", rs.getInt("place") == 0 ? null : rs.getInt("place"));
                registeredCourses.add(course);
            }

            info.add("registered", new Gson().toJsonTree(registeredCourses));
        }

        try (PreparedStatement st = conn.prepareStatement(
                "SELECT code, name, credits, grade FROM Courses NATURAL JOIN PassedCourses NATURAL JOIN Taken WHERE student=?;"))
        {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();
            List<JsonObject> finishedCourses = new ArrayList<>();

            while (rs.next()) {
                JsonObject course = new JsonObject();
                course.addProperty("course", rs.getString("name"));
                course.addProperty("code", rs.getString("code"));
                course.addProperty("credits", rs.getFloat("credits"));
                course.addProperty("grade", rs.getString("grade"));
                finishedCourses.add(course);
            }

            info.add("finished", new Gson().toJsonTree(finishedCourses));
        }

        try (PreparedStatement st = conn.prepareStatement(
                "SELECT seminarCourses, mathCredits, researchCredits, totalCredits, qualified FROM PathToGraduation WHERE student=?;")) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();

            if (rs.next()) {
                info.addProperty("seminarCourses", rs.getInt("seminarCourses"));
                info.addProperty("mathCredits", rs.getFloat("mathCredits"));
                info.addProperty("researchCredits", rs.getFloat("researchCredits"));
                info.addProperty("totalCredits", rs.getFloat("totalCredits"));
                info.addProperty("canGraduate", rs.getString("qualified").equals("t"));
            }
        }
        return new Gson().toJson(info);
    }
}