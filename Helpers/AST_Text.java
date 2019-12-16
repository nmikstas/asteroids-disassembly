package ast_text;

import java.util.StringTokenizer;

public class AST_Text 
{
    //English
    int address = 0x5729;
    String coded = "63 56 60 6E 3C EC 4D C0 A4 0A EA 6C 08 00 EC F2 "
                 + "B0 6E 3C EC 48 5A B8 66 92 42 9A 82 C3 12 0E 12 "
                 + "90 4C 4D F1 A4 12 2D D2 0A 64 C2 6C 0F 66 CD 82 "
                 + "6C 9A C3 4A 85 C0 A6 6E 60 6C 9E 0A C2 42 C4 C2 "
                 + "BA 60 49 F0 0C 12 C6 12 B0 00 A6 6E 60 58 ED 12 "
                 + "B5 E8 29 D2 0E D8 4C 82 82 70 C2 6C 0B 6E 09 E6 "
                 + "B5 92 3E 00 A6 6E 60 6E C1 6C C0 00 59 62 48 66 "
                 + "D2 6D 18 4E 9B 64 09 02 A4 0A ED C0 18 4E 9B 64 "
                 + "08 C2 A4 0A E8 00 20 4E 9B 64 B8 46 0D 20 2F 40";
    
    /*
    //Spanish
    int address = 0x79FE;
    String coded = "B2 4E 9D 90 B8 00 76 56 2A 26 B0 40 BE 42 A6 64 "
                 + "C1 5C 48 52 BE 0A 0A 64 C5 92 0C 26 B8 50 6A 7C "
                 + "0C 52 74 EC 4D C0 A4 EC 0A 8A D4 EC 0A 64 C5 92 "
                 + "0D F2 B8 5A 93 4E 69 60 4D C0 9D 2C 6C 4A 0D A6 "
                 + "C1 70 48 68 2D 8A 0D D2 82 4E 3B 66 91 6C 0C 0A "
                 + "0C 12 C5 8B 9D 2C 6C 4A 0B 3A A2 6C BD 0A 3A 40 "
                 + "A6 60 B9 6C 0D F0 2D B1 76 52 5C C2 C2 6C 8B 64 "
                 + "2A 27 18 54 69 D8 28 48 0B B2 4A E6 B8 00 18 54 "
                 + "69 D8 28 46 0B B2 4A E7 20 54 69 D8 2D C2 18 5C "
                 + "CA 56 98 00";
    */
    /*
    //German
    int address = 0x789A;
    String coded = "64 D2 3B 2E C2 6C 5A 4C 93 6F BD 1A 4C 12 B0 40 "
                 + "6B 2C 0A 6C 5A 4C 93 6E 0B 6E C0 52 6C 92 B8 50 "
                 + "4D 82 F2 58 90 4C 4D F0 4C 80 33 70 C2 42 5A 4C "
                 + "4C 82 BB 52 0B 58 B2 42 6C 9A C3 4A 82 64 0A 5A "
                 + "90 00 F6 6C 09 B2 3B 2E C1 4C 4C B6 2B 20 0D A6 "
                 + "C1 70 48 50 B6 52 3B D2 90 00 DA 64 90 4C C9 D8 "
                 + "BE 0A 32 42 9B C2 67 68 4D AE A1 4E 48 50 B6 52 "
                 + "3B D2 90 00 BE 0A B6 1E 94 D2 A2 92 0A 2C CA 4E "
                 + "7A 65 BD 1A 4C 12 92 13 18 62 CA 64 F2 42 20 6E "
                 + "A3 52 82 40 18 62 CA 64 F2 42 18 6E A3 52 80 00 "
                 + "20 62 CA 64 F2 64 08 C2 BD 1A 4C 00";
    */
    /*
    //French
    int address = 0x7951;
    String coded = "8A 5A 84 12 CD 82 B9 E6 B2 40 74 F2 4D 83 D4 F0 "
                 + "B2 42 B9 E6 B2 42 4D F0 0E 64 0A 12 B8 46 10 62 "
                 + "4B 60 82 72 B5 C0 BE A8 0A 64 C5 92 F0 74 9D C2 "
                 + "6C 9A C3 4A 82 6F A4 F2 BD D2 F0 6C 9E 0A C2 42 "
                 + "A4 F2 B0 74 9D C2 6C 9A C3 4A 82 6F A4 F2 BD D2 "
                 + "F0 58 ED 12 B5 E8 29 D2 0D 72 2C 90 0C 12 C6 2C "
                 + "48 4E 9D AC 49 F0 48 00 2D 28 CF 52 B0 6E CD 82 "
                 + "BE 0A B6 00 53 64 0A 12 0D 0A B6 1A 48 00 18 68 "
                 + "6A 4E 48 48 0B A6 CA 72 B5 C0 18 68 6A 4E 48 46 "
                 + "0B A6 CA 72 B0 00 20 68 6A 4E 4D C2 18 5C 9E 52 "
                 + "CD 80";
    */
    
    //Array of character values.
    String[] chars = 
    {
        " NULL", "  _  ", "  0  ", "  1  ", "  2  ", "  A  ", "  B  ", "  C  ",
        "  D  ", "  E  ", "  F  ", "  G  ", "  H  ", "  I  ", "  J  ", "  K  ",
        "  L  ", "  M  ", "  N  ", "  O  ", "  P  ", "  Q  ", "  R  ", "  S  ",
        "  T  ", "  U  ", "  V  ", "  W  ", "  X  ", "  Y  ", "  Z  ", " NULL"
    };
    
    //Array of characters for building a readable string.
    String[] read = 
    {
         "", " ", "0", "1", "2", "A", "B", "C",
        "D", "E", "F", "G", "H", "I", "J", "K",
        "L", "M", "N", "O", "P", "Q", "R", "S",
        "T", "U", "V", "W", "X", "Y", "Z", ""
    };
        
    //Array of binary values
    String[] bins =
    {
        "00000", "00001", "00010", "00011", "00100", "00101", "00110", "00111",
        "01000", "01001", "01010", "01011", "01100", "01101", "01110", "01111",
        "10000", "10001", "10010", "10011", "10100", "10101", "10110", "10111",
        "11000", "11001", "11010", "11011", "11100", "11101", "11110", "XXXXX"
    };
    
    public static void main(String[] args)
    {
        AST_Text ast = new AST_Text();
        StringTokenizer st = new StringTokenizer(ast.coded, " ");
        int[] charIndexes = new int[3];
        String readTextString = ";";
        String textRowString = ";             ";
        String binaryRowString = ";             ";
        String byteRowString = "L" + Integer.toHexString(ast.address).toUpperCase() + ":  .byte     ";
        int stopBit;
        int byte0, byte1;
        int bytesThisRow = 0;
        
        while(st.hasMoreElements())
        {
            //Get next byte pair in the data string.
            byte1 = Integer.parseInt(st.nextToken(), 16);
            byte0 = Integer.parseInt(st.nextToken(), 16);
            
            //Get the indexes into the chars array for the characters.
            charIndexes = ast.getCharIndexes(byte1, byte0);
            
            //Build the text row string.
            textRowString += ast.chars[charIndexes[2]] + " " +
                             ast.chars[charIndexes[1]] + " " +
                             ast.chars[charIndexes[0]] + "    ";
            
            //Build readable text string.
            readTextString += ast.read[charIndexes[2]] +
                              ast.read[charIndexes[1]] + 
                              ast.read[charIndexes[0]];
            
            //Get stop bit.
            stopBit = byte0 & 0x00000001;
            
            //Build the binary row string.
            binaryRowString += ast.bins[charIndexes[2]] + "_" +
                               ast.bins[charIndexes[1]] + "_" +
                               ast.bins[charIndexes[0]] + "_" + stopBit;
            
            //Convert hex data back into strings.
            String b1 = Integer.toHexString(byte1).toUpperCase();
            String b0 = Integer.toHexString(byte0).toUpperCase();
            if(b1.length() == 1) b1 = "0" + b1;
            if(b0.length() == 1) b0 = "0" + b0;
            
            //Build the byte row string.
            byteRowString += "$" + b1 + ", $" + b0;
                     
            bytesThisRow = bytesThisRow + 2; //Increment byte count.            
            ast.address = ast.address + 2; //Move to next address value.
            
            //Update variables after a pair of bytes have been processed.
            if((bytesThisRow == 8) || (stopBit == 1 || charIndexes[0] == 0))
            {
                bytesThisRow = 0;
                System.out.println(textRowString);
                System.out.println(binaryRowString);
                System.out.println(byteRowString);
                
                textRowString = ";             ";
                binaryRowString = ";             ";
                byteRowString = "L" + Integer.toHexString(ast.address).toUpperCase() + ":  .byte     ";
            }
            else
            {
                binaryRowString += ", ";
                byteRowString += ",            ";
            }
            
            //Update readable string.
            if(stopBit == 1 || charIndexes[0] == 0)
            {
                System.out.println(readTextString); 
                readTextString = ";";
            }
        }   
    }    
    
    //charNum is 0, 1 or 2.  breaks down a 16-bit word into three index values:
    //00000_11111_22222_X
    int[] getCharIndexes(int byte1, int byte0)
    {
        int[] charIndex = new int[3];
        int charWord = (byte1 << 8) | byte0;
        charWord &= 0x0000FFFF;
        
        charIndex[2] = charWord & 0x0000F800;
        charIndex[2] >>= 11;
               
        charIndex[1] = charWord & 0x000007C0;
        charIndex[1] >>= 6;
                
        charIndex[0] = charWord & 0x0000003E;
        charIndex[0] >>= 1;
                   
        return charIndex;
    }
}
