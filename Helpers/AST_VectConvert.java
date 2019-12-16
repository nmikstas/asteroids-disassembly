package ast_vectconvert;

import java.util.StringTokenizer;

public class AST_VectConvert
{
    //Diag step graphics.
    int address = 0x7EC0;
    String coded = "80 A0 00 00 00 70 00 00 FF 92 FF 73 D0 A1 30 02 "
                 + "00 70 00 00 7F FB 0D E0 00 B0 7E FA 11 C0 78 FE "
                 + "00 B0 13 C0 00 D0 15 C0 00 D0 17 C0 00 D0 7A F8 "
                 + "00 D0";
    
    /*
    //From ship graphics through the character pointer table. 
    int address = 0x5290;
    String coded = "0F F6 C8 FA BD F9 00 65 00 C3 00 65 00 C7 B9 F9 "
                 + "00 D0 CE F9 CA F9 00 D0 40 46 C0 06 00 52 30 C4 "
                 + "C0 41 20 C6 B0 64 18 C3 48 65 E0 C6 20 42 C0 C1 "
                 + "00 D0 D0 50 10 C6 60 42 C0 C3 00 D0 80 46 80 06 "
                 + "E0 43 C0 C4 A0 41 60 C6 68 64 20 C3 90 65 C0 C6 "
                 + "60 42 A0 C1 00 D0 90 50 30 C6 C0 42 80 C3 00 D0 "
                 + "C0 46 40 06 E0 43 20 C5 60 41 80 C6 18 64 28 C3 "
                 + "D0 65 98 C6 80 42 60 C1 00 D0 60 50 30 C6 20 43 "
                 + "40 C3 00 D0 0E F7 C0 43 80 C5 20 41 A0 C6 38 60 "
                 + "28 C3 10 66 60 C6 A0 42 20 C1 00 D0 30 50 40 C6 "
                 + "60 43 E0 C2 00 D0 20 47 C0 05 80 43 E0 C5 E0 40 "
                 + "C0 C6 88 60 20 C3 48 66 30 C6 C0 42 E0 C0 00 D0 "
                 + "10 54 40 C6 A0 43 A0 C2 00 D0 60 47 60 05 60 43 "
                 + "40 C6 80 40 C0 C6 D8 60 10 C3 80 66 F0 C5 C0 42 "
                 + "80 C0 00 D0 40 54 30 C6 E0 43 40 C2 00 D0 80 47 "
                 + "00 05 20 43 80 C6 40 40 E0 C6 20 61 F8 C2 B0 66 "
                 + "B0 C5 E0 42 40 C0 00 D0 80 54 30 C6 10 52 F0 C0 "
                 + "00 D0 80 47 C0 04 E0 42 E0 C6 00 40 E0 C6 68 61 "
                 + "D8 C2 D8 66 68 C5 E0 42 00 C0 00 D0 B0 54 20 C6 "
                 + "20 52 B0 C0 00 D0 A0 47 60 04 80 42 20 C7 40 44 "
                 + "E0 C6 B0 61 B0 C2 F8 66 20 C5 E0 42 40 C4 00 D0 "
                 + "F0 54 10 C6 30 52 80 C0 00 D0 A0 47 00 00 40 42 "
                 + "60 C7 80 44 C0 C6 F0 61 80 C2 10 67 D8 C4 C0 42 "
                 + "80 C4 00 D0 40 46 E0 C7 30 52 40 C0 00 D0 A0 47 "
                 + "60 00 E0 41 80 C7 E0 44 C0 C6 30 62 48 C2 20 67 "
                 + "88 C4 C0 42 E0 C4 00 D0 A0 46 A0 C7 40 52 10 C0 "
                 + "00 D0 80 47 C0 00 80 41 C0 C7 20 45 A0 C6 60 62 "
                 + "10 C2 28 67 38 C4 A0 42 20 C5 00 D0 E0 46 60 C7 "
                 + "40 52 30 C4 00 D0 80 47 00 01 20 41 E0 C7 60 45 "
                 + "80 C6 98 62 D0 C1 28 67 18 C0 80 42 60 C5 00 D0 "
                 + "40 47 20 C7 30 52 60 C4 00 D0 60 47 60 01 C0 40 "
                 + "E0 C7 A0 45 60 C6 C0 62 90 C1 20 67 68 C0 60 42 "
                 + "A0 C5 00 D0 80 47 C0 C6 30 52 90 C4 00 D0 20 47 "
                 + "C0 01 30 50 00 C6 C0 45 20 C6 E0 62 48 C1 18 67 "
                 + "B0 C0 20 42 C0 C5 00 D0 C0 47 60 C6 10 52 D0 C4 "
                 + "00 D0 0A F7 CE F8 CD FD 00 63 00 C1 00 67 00 C1 "
                 + "CD F9 00 D0 CD FE CD FA 00 D0 0E F7 7A F8 79 FD "
                 + "00 63 00 75 00 67 00 75 79 F9 C0 60 80 02 9F D0 "
                 + "70 FA 72 F2 72 F6 70 FE 06 F9 72 F8 02 F6 00 D0 "
                 + "70 FB 73 F0 71 F5 70 F5 75 F5 77 F0 03 F0 71 F5 "
                 + "70 F5 75 F5 77 F0 03 F8 00 D0 70 FB 72 F8 06 FF "
                 + "72 F8 02 F0 00 D0 70 FB 72 F0 72 F6 70 F6 76 F6 "
                 + "76 F0 03 F8 00 D0 70 FB 72 F8 05 F7 77 F0 00 F7 "
                 + "72 F8 02 F0 00 D0 70 FB 72 F8 05 F7 77 F0 00 F7 "
                 + "03 F8 00 D0 70 FB 72 F8 70 F6 06 F6 72 F0 70 F6 "
                 + "76 F8 03 F8 00 D0 70 FB 00 F7 72 F8 00 F3 70 FF "
                 + "02 F0 00 D0 72 F8 06 F0 70 FB 02 F0 76 F8 03 FF "
                 + "00 D0 00 F2 72 F6 72 F0 70 FB 01 FF 00 D0 70 FB "
                 + "03 F0 77 F7 73 F7 03 F0 00 D0 00 FB 70 FF 72 F8 "
                 + "02 F0 00 D0 70 FB 72 F6 72 F2 70 FF 02 F0 00 D0 "
                 + "70 FB 72 FF 70 FB 01 FF 00 D0 70 FB 72 F8 70 FF "
                 + "76 F8 03 F8 00 D0 70 FB 72 F8 70 F7 76 F8 03 F7 "
                 + "03 F0 00 D0 70 FB 72 F8 70 FE 76 F6 76 F0 02 F2 "
                 + "72 F6 02 F0 00 D0 70 FB 72 F8 70 F7 76 F8 01 F0 "
                 + "73 F7 02 F0 00 D0 72 F8 70 F3 76 F8 70 F3 72 F8 "
                 + "01 FF 00 D0 02 F0 70 FB 06 F0 72 F8 01 FF 00 D0 "
                 + "00 FB 70 FF 72 F8 70 FB 01 FF 00 D0 00 FB 71 FF "
                 + "71 FB 01 FF 00 D0 00 FB 70 FF 72 F2 72 F6 70 FB "
                 + "01 FF 00 D0 72 FB 06 F8 72 FF 02 F0 00 D0 02 F0 "
                 + "70 FA 76 F2 02 F8 76 F6 02 FE 00 D0 00 FB 72 F8 "
                 + "76 FF 72 F8 02 F0 00 D0 03 F8 00 D0 02 F0 70 FB "
                 + "02 FF 00 D0 00 FB 72 F8 70 F7 76 F8 70 F7 72 F8 "
                 + "02 F0 00 D0 72 F8 70 FB 76 F8 00 F7 72 F8 02 F7 "
                 + "00 D0 00 FB 70 F7 72 F8 00 F3 70 FF 02 F0 00 D0 "
                 + "72 F8 70 F3 76 F8 70 F3 72 F8 01 FF 00 D0 00 F3 "
                 + "72 F8 70 F7 76 F8 70 FB 03 FF 00 D0 00 FB 72 F8 "
                 + "70 FF 02 F0 00 D0 72 F8 70 FB 76 F8 70 FF 00 F3 "
                 + "72 F8 02 F7 00 D0 02 F8 70 FB 76 F8 70 F7 72 F8 "
                 + "02 F7 00 D0 2C CB DD CA 2E CB 32 CB 3A CB 41 CB "
                 + "48 CB 4F CB 56 CB 5B CB 63 CB 78 CA 80 CA 8D CA "
                 + "93 CA 9B CA A3 CA AA CA B3 CA BA CA C1 CA C7 CA "
                 + "CD CA D2 CA D8 CA DD CA E3 CA EA CA F3 CA FB CA "
                 + "02 CB 08 CB 0E CB 13 CB 1A CB 1F CB 26 CB";
    */
    
    /*
    //From the test pattern through the saucer pattern pointer table.
    int address = 0x5000;
    String coded = "80 A0 00 00 00 70 00 00 00 90 FF 73 FF 92 00 70 "
                 + "00 90 FF 77 FF 96 00 70 FF 92 FF 72 00 86 00 72 "
                 + "FE 87 FE 77 00 92 00 76 FE 81 00 72 FF 96 FF 72 "
                 + "7F A3 FF 03 00 70 00 00 FF 96 FF 76 FE 81 00 76 "
                 + "00 92 00 72 FE 87 FE 73 00 86 00 76 FF 92 FF 76 "
                 + "FC A1 F4 01 00 70 00 00 DB F0 00 F9 CF F0 00 F9 "
                 + "BB F0 00 F9 AF F0 00 F9 9B F0 00 F9 8F F0 00 F9 "
                 + "7B F0 00 F9 6F F0 00 F9 5B F0 00 F9 4F F0 00 F9 "
                 + "3B F0 00 F9 2F F0 7C D0 E4 A0 5E 11 00 70 00 00 "
                 + "80 CA 78 CA D8 CA C7 CA 2C CB 9B CA F3 CA F3 CA "
                 + "DD CA F3 EA 80 A0 90 01 00 70 00 00 73 F5 73 F1 "
                 + "78 F1 77 F1 77 F5 78 F5 80 31 00 02 75 F8 70 FD "
                 + "71 F8 02 FD 2E CB 63 CB 56 CB 63 CB 2C CB 78 CA "
                 + "02 CB 78 CA F3 CA BA CA 2C CB BA CA D8 CA 8D EA "
                 + "C6 FF C1 FE C3 F1 CD F1 C7 F1 C1 FD D8 1E 32 EC "
                 + "00 C4 3C 14 0A 46 D8 D8 D0 C8 B5 C8 96 C8 80 C8 "
                 + "0D F8 78 F8 0D FD 78 F8 09 FD 78 F8 0B F1 78 F8 "
                 + "0A F5 78 F8 08 F9 78 F8 09 F3 78 F8 0D F3 78 F8 "
                 + "80 54 00 06 78 F8 0F F1 78 F8 00 D0 00 30 80 07 "
                 + "78 F8 80 37 80 07 78 F8 80 37 80 03 78 F8 E0 40 "
                 + "A0 02 78 F8 C0 35 80 03 78 F8 80 33 00 00 78 F8 "
                 + "A0 42 E0 00 78 F8 A0 42 E0 04 78 F8 E0 44 80 07 "
                 + "78 F8 E0 40 A0 06 78 F8 00 D0 07 F8 78 F8 07 FF "
                 + "78 F8 03 FF 78 F8 C0 40 40 02 78 F8 80 35 00 03 "
                 + "78 F8 00 FB 78 F8 40 42 C0 00 78 F8 40 42 C0 04 "
                 + "78 F8 C0 44 00 07 78 F8 C0 40 40 06 78 F8 00 D0 "
                 + "00 30 80 06 78 F8 80 36 80 06 78 F8 80 36 80 02 "
                 + "78 F8 40 31 C0 03 78 F8 40 35 80 02 78 F8 80 32 "
                 + "00 00 78 F8 C0 33 40 01 78 F8 C0 33 40 05 78 F8 "
                 + "A0 44 80 06 78 F8 40 31 C0 07 78 F8 00 D0 F3 C8 "
                 + "FF C8 0D C9 1A C9 08 F9 79 F9 79 FD 7D F6 79 F6 "
                 + "8F F6 8F F0 7D F9 78 FA 79 F9 79 FD 00 D0 0A F1 "
                 + "7A F1 7D F9 7E F5 7E F1 7D FD 79 F6 7D F6 79 FD "
                 + "79 F1 8B F5 8A F3 7D F9 00 D0 0D F8 7E F5 7A F7 "
                 + "7A F3 78 F7 79 F8 7A F3 78 F9 7E F3 7F F0 7F F7 "
                 + "7A F5 00 D0 09 F0 7B F1 68 F1 7F F2 7F F0 69 F6 "
                 + "7F F0 78 F7 7A F7 7B F1 69 F5 69 F9 7F F2 00 D0 "
                 + "29 C9 0E F1 CA F8 0B F6 00 60 80 D6 DB F6 CA F8 "
                 + "DB F2 DF F2 CD F2 CD F8 CD F6 DF F6 00 D0";
    */
    
    static String[] vecScaleArray  = {"512", "256", "128", "64", "32", "16", "8", "4", "2", "1"};
    static String[] svecScaleArray = {"128", "64", "32", "16"};
    
    public static void main(String[] args)
    {
        AST_VectConvert ast = new AST_VectConvert();
        StringTokenizer st = new StringTokenizer(ast.coded, " ");
        String dataString;
        
        String upperWord0;
        String lowerWord0;
        String upperWord1;
        String lowerWord1;
        
        int opcode;
        int scale;
        int scale_;
        int brightness;
        int ysign;
        int xsign;
        int y;
        int x;
        
        while(st.hasMoreElements())
        {
            dataString = "L" + Integer.toHexString(ast.address).toUpperCase() + ":  .word $";
            ast.address += 2;
            
            //Get first word, lower byte first.
            lowerWord0 = st.nextToken();
            upperWord0 = st.nextToken();
            
            dataString += upperWord0 + lowerWord0;
            
            //Determine what the opcode is.
            opcode = Integer.parseInt(upperWord0, 16) >> 4;
            
            if(opcode < 9) opcode = 9;
            
            switch(opcode)
            {
                case 0x09: //VEC
                    ast.address += 2;
                    lowerWord1 = st.nextToken();
                    upperWord1 = st.nextToken();
                    dataString += ", $" + upperWord1 + lowerWord1 + "      ;VEC  ";
                    
                    scale = Integer.parseInt(upperWord0, 16) >> 4;
                    brightness = Integer.parseInt(upperWord1, 16) >> 4;
                    
                    ysign  = Integer.parseInt(upperWord0, 16) >> 2;
                    ysign &= 0x1;
                    
                    xsign  = Integer.parseInt(upperWord1, 16) >> 2;
                    xsign &= 0x1;
                    
                    y = Integer.parseInt(upperWord0 + lowerWord0, 16);
                    y &= 0x3FF;
                    
                    x = Integer.parseInt(upperWord1 + lowerWord1, 16);
                    x &= 0x3FF;
                    
                    dataString += "scale=" + scale + "(/" + vecScaleArray[scale] + ")";
                    
                    if(scale < 3) dataString += " ";
                    else if(scale < 6) dataString += "  ";
                    else dataString += "   ";    
                    
                    dataString += "x=";
                    if(xsign == 1) dataString += "-";
                    dataString += x;
                    
                    if(xsign != 1) dataString += " ";
                    if(x > 999) dataString += " ";
                    else if(x > 99) dataString += "  ";
                    else if(x > 9) dataString += "   ";
                    else dataString += "    ";
                    
                    dataString += "y=";
                    if(ysign == 1) dataString += "-";
                    dataString += y;
                    
                    if(ysign != 1) dataString += " ";
                    if(y > 999) dataString += " ";
                    else if(y > 99) dataString += "  ";
                    else if(y > 9) dataString += "   ";
                    else dataString += "    ";
                    
                    dataString += "b=";
                    dataString += brightness;                   
                    break;
                    
                case 0x0A: //CUR
                    ast.address += 2;
                    lowerWord1 = st.nextToken();
                    upperWord1 = st.nextToken();
                    dataString += ", $" + upperWord1 + lowerWord1 + "      ;CUR  ";
                    
                    scale = Integer.parseInt(upperWord1, 16) >> 4;
                    
                    y = Integer.parseInt(upperWord0 + lowerWord0, 16);
                    y &= 0x3FF;
                    
                    x = Integer.parseInt(upperWord1 + lowerWord1, 16);
                    x &= 0x3FF;
                    
                    dataString += "scale=" + scale + "(/" + vecScaleArray[scale] + ")";
                    
                    if(scale < 3) dataString += " ";
                    else if(scale < 6) dataString += "  ";
                    else dataString += "   ";    
                    
                    dataString += "x=";
                    dataString += x;
                    
                    if(x > 999) dataString += "  ";
                    else if(x > 99) dataString += "   ";
                    else if(x > 9) dataString += "    ";
                    else dataString += "     ";
                    
                    dataString += "y=";
                    dataString += y;
                    
                    if(y > 999) dataString += " ";
                    else if(y > 99) dataString += "  ";
                    else if(y > 9) dataString += "   ";
                    else dataString += "    ";                    
                    break;
                    
                case 0x0B: //HALT
                    dataString += "             ;HALT ";
                    break;
                    
                case 0x0C: //JSR
                    y = Integer.parseInt(upperWord0 + lowerWord0, 16);
                    y &= 0xFFF;
                    y *= 2;
                    y += 0x4000;
                    
                    dataString += "             ;JSR  $" + Integer.toHexString(y).toUpperCase();
                    break;
                    
                case 0x0D: //RTS
                    dataString += "             ;RTS ";
                    break;
                    
                case 0x0E: //JMP
                    y = Integer.parseInt(upperWord0 + lowerWord0, 16);
                    y &= 0xFFF;
                    y *= 2;
                    y += 0x4000;
                    
                    dataString += "             ;JMP  $" + Integer.toHexString(y).toUpperCase();
                    break;
                    
                default: //SVEC
                    scale = Integer.parseInt(lowerWord0, 16) >> 2;
                    scale &= 0x2;
                    scale_ = Integer.parseInt(upperWord0, 16) >> 3;
                    scale_ &= 0x1;
                    scale |= scale_;
                    
                    brightness = Integer.parseInt(lowerWord0, 16) >> 4;
                    
                    ysign = Integer.parseInt(upperWord0, 16) >> 2;
                    ysign &= 0x1;
                    xsign = Integer.parseInt(lowerWord0, 16) >> 2;
                    xsign &= 0x1;
                    
                    y = Integer.parseInt(upperWord0, 16) & 3;
                    x = Integer.parseInt(lowerWord0, 16) & 3;
                    
                    dataString += "             ;SVEC ";
                    dataString += "scale=" + scale + "(/" + svecScaleArray[scale] + ")";
                    
                    if(scale < 1) dataString += " ";
                    else if(scale < 6) dataString += "  ";
                    else dataString += "   ";    
                    
                    dataString += "x=";
                    if(xsign == 1) dataString += "-";
                    dataString += x;
                    
                    if(xsign != 1) dataString += " ";
                    if(x > 999) dataString += " ";
                    else if(x > 99) dataString += "  ";
                    else if(x > 9) dataString += "   ";
                    else dataString += "    ";
                    
                    dataString += "y=";
                    if(ysign == 1) dataString += "-";
                    dataString += y;
                    
                    if(ysign != 1) dataString += " ";
                    if(y > 999) dataString += " ";
                    else if(y > 99) dataString += "  ";
                    else if(y > 9) dataString += "   ";
                    else dataString += "    ";
                    
                    dataString += "b=";
                    dataString += brightness;
                    break;
            }
            
            System.out.println(dataString);
        }        
    }
}
