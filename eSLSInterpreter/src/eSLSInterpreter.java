import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Reader;
import java.nio.charset.Charset;
import java.util.TreeMap;

import javax.script.Bindings;
import javax.script.Compilable;
import javax.script.CompiledScript;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.SimpleBindings;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;

@SuppressWarnings("unused")
public class eSLSInterpreter
{
	private TreeMap<String, Integer> points;
	private String scriptFilePath;
	private String outputFilePath;

	public eSLSInterpreter()
	{
		points = new TreeMap<String, Integer>();
		// GUI to find filepath
		this.scriptFilePath = "C:\\Users\\wzbvnr\\workspace\\eSLSInterpreter\\src\\eSLS.lua"; // Should be GUI returned value
		loadVariables();
		this.outputFilePath = "eSLSInterpreterOutput.txt"; //Should be GUI returned value
		printOutputFile();
	}
	/**
	 * This method loads the variables from the saved variables file. This is meant to load
	 * in the lua file and convert them into a Java usable object to further allow calculations
	 * as we see fit.
	 * This requires the filepath to the file we want to read to already be set up, which should
	 * be taken care of by the gui requests.
	 */
	private void loadVariables()
	{
		if(this.scriptFilePath.isEmpty())
		{
			//Error out somehow
			return;
		}
	     Reader reader;
	     ScriptEngineManager mgr;
	     ScriptEngine e;
	     Bindings b;
	     CompiledScript cs;	     
          try
          {
	          reader = new FileReader(this.scriptFilePath);
	          mgr = new ScriptEngineManager();
		     e = mgr.getEngineByExtension(".lua");
		     b = new SimpleBindings();
		     cs = ((Compilable)e).compile(reader);
		     System.out.println( "eval: "+cs.eval(b) );

               Object something = b.get("eSLS_stdBid");
		     
		     // Points table
		     LuaTable luaPoints = (LuaTable)b.get("eSLS_points");
		     System.out.println(luaPoints.keyCount());
		     
		     // Loot Tracking table
		     LuaTable luaLootTracking = (LuaTable)b.get("eSLS_winners");
		     System.out.println(luaLootTracking.keyCount());
		     
		     for(int i=0; i < luaPoints.keys().length; i++)
		     {
		     	LuaValue v = luaPoints.keys()[i];
		     	points.put(v.toString(), luaPoints.get(v).toint());
		     	
		     }

          } catch (Exception e1) {
	          e1.printStackTrace();
          }       
	}
	
	/**
	 * This method provides output of the variables we were looking at, in a tab delimited 
	 * format. This will make it easier to read, as well as make it available for upload
	 * in google docs/ or for archiving purposes.
	 */
	private void printOutputFile()
	{
		File n;
	     FileWriter fos = null;
		try
          {
		     n = new File(this.outputFilePath);
		     fos = new FileWriter(n);
	          for( String s : points.keySet())
	          {
		     	fos.write(s + "\t" + points.get(s) + "\n");
	          }
          } catch (IOException e)
          {
          	//GUI print Error; Error in writing output to file
	          e.printStackTrace();
          } finally {
          	try
               {
	               if(fos != null)
	               {
	               	fos.flush();
	               	fos.close();
	               }
               } catch (IOException e)
               {
               	// GUI print Error; Streams could not be closed.
               	e.printStackTrace();
               }
          }
	}
}
