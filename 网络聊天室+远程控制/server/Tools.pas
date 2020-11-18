unit Tools;

interface

function CalCRC16(AData: PByte; AStart, AEnd: Integer): Word;

implementation
uses SysUtils, StrUtils;
function CalCRC16(AData: PByte; AStart, AEnd: Integer): Word;
const
  GENP = $8408;  //����ʽ��ʽX16+X15+X2+1��1100 0000 0000 0101��  //$A001
var
  crc: Word;
  i: Integer;
  tmp: Byte;
  s: string;

  procedure CalOneByte(AByte: Byte);  //����1���ֽڵ�У����
  var
    j: Integer;
  begin
    crc := crc xor AByte;   //��������CRC�Ĵ����ĵ�8λ�������
    for j := 0 to 7 do      //��ÿһλ����У��
    begin
      tmp := crc and 1;        //ȡ�����λ
      crc := crc shr 1;        //�Ĵ���������һλ
      crc := crc and $7FFF;    //�����λ��0
      if tmp = 1 then         //����Ƴ���λ�����Ϊ1����ô�����ʽ���
        crc := crc xor GENP;
      crc := crc and $FFFF;
    end;
  end;

begin
  crc := $FFFF;             //�������趨ΪFFFF
  Inc(AData, AStart);
  for i := AStart to AEnd do   //��ÿһ���ֽڽ���У��
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

