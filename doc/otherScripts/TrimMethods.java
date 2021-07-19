
import java.io.*;
import org.apache.bcel.classfile.ClassParser;
import org.apache.bcel.classfile.JavaClass;
import org.apache.bcel.classfile.Method;
import org.apache.bcel.classfile.LineNumberTable;

public class TrimMethods {
	public static void main(String[] args) {
		try {

			File f = new File(args[0]);

			if (!f.exists()) {
				System.err.println("Class file " + args[0] + " does not exist");
			}			
			else
			{
				JavaClass clazz;
				ClassParser cp = new ClassParser(args[0]);
				clazz = cp.parse();

				if ( args[1].equals("allBut") )
				trimItAllBut(clazz.getMethods(), args[0]);
				//else if (args[2] == theseOnly);
			}
		}
		catch(IOException e)
		{
			System.err.println(e);
		}
	}

	public static void trimItAllBut(Method[] methods, String logFile) {
		//try {
		//	File fLog = new File(logFile);
		//}
		//catch(IOException e)
		//{
		//	System.err.println(e);
		//}
			for (int i = 1; i < methods.length; i++) {
				String[] splitOne = methods[i].toString().split("\\(");
				String[] splitTwo = splitOne[splitOne.length - 2].split(" ");
				System.out.println(splitTwo[splitTwo.length - 1]);
				LineNumberTable theTable = methods[i].getLineNumberTable();
				System.out.println(theTable.toString());
			}
	}
}