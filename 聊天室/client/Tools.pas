unit Tools;

interface

function CalCRC16(AData: PByte; AStart, AEnd: Integer): Word;

implementation
uses SysUtils, StrUtils;
function CalCRC16(AData: PByte; AStart, AEnd: Integer): Word;
const
  GENP = $8408;  //多项式公式X16+X15+X2+1（1100 0000 0000 0101）  //$A001
var
  crc: Word;
  i: Integer;
  tmp: Byte;
  s: string;

  procedure CalOneByte(AByte: Byte);  //计算1个字节的校验码
  var
    j: Integer;
  begin
    crc := crc xor AByte;   //将数据与CRC寄存器的低8位进行异或
    for j := 0 to 7 do      //对每一位进行校验
    begin
      tmp := crc and 1;        //取出最低位
      crc := crc shr 1;        //寄存器向右移一位
      crc := crc and $7FFF;    //将最高位置0
      if tmp = 1 then         //检测移出的位，如果为1，那么与多项式异或
        crc := crc xor GENP;
      crc := crc and $FFFF;
    end;
  end;

begin
  crc := $FFFF;             //将余数设定为FFFF
  Inc(AData, AStart);
  for i := AStart to AEnd do   //对每一个字节进行校验
  begin
    CalOneByte(AData^);
    Inc(AData);
    //OutputDebugString(PChar(inttostr(AData[i])));
  end;

  Result := crc;
  //s := inttohex(crc, 2);

  //Result := Hextoint(rightstr(s, 2) + leftstr(s, 2));
end;

end.

