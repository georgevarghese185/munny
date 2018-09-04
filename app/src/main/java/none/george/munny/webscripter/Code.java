package none.george.munny.webscripter;

import android.content.Context;

import java.io.BufferedReader;
import java.io.InputStreamReader;

public class Code {
    private String codeSnippet;

    public Code(Context context, String filePath, String snippetName) {
        codeSnippet = readFromFile(context, filePath, snippetName);
        codeSnippet = codeSnippet.replace("{{interface}}", Steps.INTERFACE_NAME);
    }

    private static String readFromFile(Context context, String filePath, String snippetName) {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(context.getAssets().open(filePath)));
            String line;

            while((line = reader.readLine()) != null) {
                if(line.equals("//" + snippetName)) {
                    break;
                }
            }

            StringBuilder code = new StringBuilder();
            while((line = reader.readLine()) != null) {
                if(line.equals("//end")) {
                    break;
                }

                code.append(line);
                code.append("\n");
            }

            return code.toString();
        } catch (Exception e) {
            return "";
        }
    }

    public Code args(String name, String value) {
        codeSnippet = codeSnippet.replace("{{" + name + "}}", value);
        return this;
    }

    public Code args(String[] names, String[] values) {
        for(int i = 0; i < names.length && i < values.length; i++) {
            args(names[i], values[i]);
        }

        return this;
    }

    @Override
    public String toString() {
        return codeSnippet;
    }
}
