import java.sql.SQLException;
import com.google.gson.Gson;

/**
 * Class to parse an SQL response into json by Googles Gson library
 */
public class JsonResponse {

    public static void main(String[] args) {
        // test of JsonRespns and gson
        SQLException err = new SQLException("error: oh no this failed");
        String e = new JsonResponse(false, err).getJson();
        System.out.println(e);

        // err = new SQLException("error: this worked :)");
        e = new JsonResponse(true, null).getJson();
        System.out.println(e);
    }

    static final Gson jsonParser = new Gson();

    private boolean success;
    private String error;

    JsonResponse(boolean success, SQLException error) {
        this.success = success;
        this.error = !success ? getError(error) : null;
    }

    // This is a hack to turn an SQLException into a JSON string error message. No
    // need to change.
    private static String getError(SQLException e) {
        String message = e.getMessage();
        int ix = message.indexOf('\n');
        if (ix > 0)
            message = message.substring(0, ix);
        message = message.replace("\"", "\\\"");
        return message;
    }

    public String getJson() {
        return jsonParser.toJson(this);
    }
}