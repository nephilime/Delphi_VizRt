unit VizUnit;

interface

uses
  SysUtils, Classes, Math, Web.Win.Sockets;

const
  VizRtLayers: array [1..3] of string = (
  '*BACK_LAYER',
  '*MIDDLE_LAYER',
  '*FRONT_LAYER');

type
  TVizMod = class(TDataModule)
    tcpclnt: TTcpClient;
  private
    { Private declarations }
    fRemoteHost : string;
    fRemotePort : string;
    fConnected  : Boolean;
  public
    { Public declarations }
    Property
      RemoteHost : string read fRemoteHost write fRemoteHost;
    Property
      RemotePort : string read fRemotePort write fRemotePort;
    Property
      VizConnected : Boolean read fConnected write fConnected;

    function VizConnect(ARemoteHost, AremotePort : string): Boolean;
    function VizReConnect(): Boolean;

    //VizCommands
    function VizSetSceneInRender(aLayer : integer; AScene : string): boolean;
    function VizReloadSceneInRender(aLayer : integer; AScene : string): boolean;

    function VizDirectorSetTime(aLayer: integer;aDirector, aTime: string): boolean;
    function VizDirectorStart(aLayer : integer; aDirector: string): boolean;
    function VizDirectorContinue(aLayer : integer; aDirector: string): boolean;
    function VizDirectorContinueRev(aLayer : integer; aDirector: string): boolean;
    function VizDirectorPause(aLayer : integer; aDirector: string): boolean;

    function VizSoftClipSetVideo(aLayer : Integer; aFiledName, aVideoPathName : string ): Boolean;

    function VizImageUpdate(aLayer : integer; aFieldName, aFilePathName: string): boolean;
    function VizImageUpdateDB(aLayer: Integer; aFiledName,aImagePathName: string): Boolean;
    function VizGeomUpdate(aLayer : integer; aFieldName, aGeomPathName: string): boolean;
    function VizTextUpdate(aLayer: Integer; aFiledName, aFiledData: string): boolean;

    function VizActiveSet(aLayer: Integer; aFieldName, aState : string): Boolean;
    function VizActiveSetPath(aLayer: Integer; aFieldName, aState : string): Boolean;

    function VizKeyValSet(aLayer: Integer; aFieldName, aKeyName, aValue: string): Boolean;

    function VizSetContainerAlpha(aLayer: Integer; aContainerName, aAlphaValue: string): Boolean;

    function VizSetContainerPosition(aLayer: Integer; aContainerName, aPositionValue: string): Boolean;


    function VizClear(aLayer: Integer): boolean;
    function VizAns(Command : string):string;

    function VizSetActiveCamera(aLayer: Integer; aCamera: string): Boolean;

    function VizPostRender(AScene, ADevice, ADuration, AName, APixelFormat : string): Boolean;

    function VizTargaPlay(): boolean;
    function VizTargaStop(): boolean;
    function VizTargaPause(): boolean;
    function VizTargaClipTimeSet(aTime: string): boolean;

    //service
    function VizTimeToFieldS(aTime: string) : string;
    function VizTimeToFieldD(aTime: string) : double;
    function VizTimeToFieldI(aTime: string) : integer;
    function VizFieldsToTime(aField :string) : string;

    function VizGetAllStopsByDirecor(alayer: Integer; aDirectorName : string): string;
    function VizGetLoadedSceneName(aLayer: Integer): string;
    function VizGetDirectorTime(aLayer: Integer; aDirector: string) : string;

  end;

var
  VizMod: TVizMod;
//  tcpclnt : TTcpClient;

implementation

{$R *.dfm}

function TVizMod.VizConnect(ARemoteHost, AremotePort: string): Boolean;
begin
  try
    fRemoteHost := ARemoteHost;
    fRemotePort := AremotePort;
    tcpclnt.RemoteHost := fRemoteHost;
    tcpclnt.RemotePort := fRemotePort;
    tcpclnt.Connect;
    Sleep(100);
  finally
    if tcpclnt.Connected then
    begin
        fConnected := True;
        Result := True;
    end
    else
    begin
      fConnected := False;
      Result := False;
    end;

//  tcpclnt := tcpclnt;
  end;
end;

function TVizMod.VizReConnect: Boolean;
begin
    if tcpclnt.Connected then
    begin
      tcpclnt.close;
    end;

    tcpclnt.Connect;
    Sleep(100);

    if tcpclnt.Connected then
    begin
        fConnected := True;
        Result := True;
    end
    else
    begin
      fConnected := False;
      Result := False;
    end;
end;


function TVizMod.VizTimeToFieldS(aTime: string): string;
var
  vTime : Extended;
  fs : TFormatSettings;
begin
  GetLocaleFormatSettings(0, fs);
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := ',';

  vTime := StrToFloat(aTime,fs);
  vTime := RoundTo(vTime,-2);

  Result := FloatToStr(vTime*100/2,fs)
end;

function TVizMod.VizTimeToFieldD(aTime: string): double;
var
  vTime : Extended;
  fs : TFormatSettings;
begin
  GetLocaleFormatSettings(0, fs);
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := ',';

  vTime := StrToFloat(aTime,fs);
  vTime := vTime*100/2;
  vTime := RoundTo(vTime,-2);
  Result := vTime;
end;

function TVizMod.VizTimeToFieldI(aTime: string): integer;
var
  vTime : Extended;
  vTimeInt: Integer;
  fs : TFormatSettings;
begin
  GetLocaleFormatSettings(0, fs);
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := ',';

  vTime := StrToFloat(aTime,fs);
  vTime := vTime*100/2;
  vTimeInt := Round(vTime);
  Result := vTimeInt;
end;

function TVizMod.VizFieldsToTime(aField: string): string;
var
  vField : Extended;
  fs : TFormatSettings;
begin
  GetLocaleFormatSettings(0, fs);
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := ',';

  vField:= StrToFloat(aField,fs);
  Result := FloatToStr(vField/100*2,fs)
end;

function TVizMod.VizAns(  Command : string):string;
var
  ans : Variant ;
  eol : string;
  len, j : integer;
  buf : array[0..6550] of char;
begin
  tcpclnt.Close;
  if not tcpclnt.Connected then
  begin
    tcpclnt.Open;
  end;

  j := 0;
  eol := '';
  
  tcpclnt.sendln(Command,#0);
  ///BLOCKING MODE TCPSOCKET
  //==================================
  len := 6550;
  tcpclnt.ReceiveBuf(Buf,len);
  while buf[j] <> #0 do
  begin
    ans := ans + buf[j];
    Inc(j);
  end;

  if ans='' then
  begin
    ans := 'Error' ;
  end;
  Result:= ans;
  //==================================
end;

function TVizMod.VizPostRender(  AScene, ADevice, ADuration, AName, APixelFormat : string): Boolean;
begin
//  if not tcpclnt.Connected then tcpclnt.Open;
  tcpclnt.sendln('10 RENDER_TO_DISK*CLIP_NAME SET "' + AName + '"',#0);
  tcpclnt.sendln('10 RENDER_TO_DISK*PLUGIN SET BUILT_IN*RENDER_TO_DISK*TgaRenderer',#0);
  tcpclnt.sendln('10 RENDER_TO_DISK*PLUGIN_INSTANCE*CodecList SET 0', #0);
  tcpclnt.sendln('10 RENDER_TO_DISK*DURATION SET ' + ADuration,#0);
  tcpclnt.sendln('10 RENDER_TO_DISK*PIXEL_FORMAT SET ' + APixelFormat,#0);
  tcpclnt.sendln('10 RENDER_TO_DISK* RECORD OVERWRITE 720 576',#0);
end;

function TVizMod.VizImageUpdateDB(  aLayer: Integer;
  aFiledName,aImagePathName: string): Boolean;
begin
  tcpclnt.sendln('1 RENDERER'+VizRtLayers[aLayer]+'*TREE*@' + aFiledName +'*IMAGE SET IMAGE*' + aImagePathName ,#0);
end;

function TVizMod.VizSetActiveCamera(  aLayer : Integer; aCamera: string): Boolean;
begin
//  if not tcpclnt.Connected then tcpclnt.Open; //FRONT_LAYER //BACK_LAYER
    tcpclnt.sendln('4 RENDERER'+VizRtLayers[aLayer]+' SET_CAMERA ' + ACamera + ' 1',#0);
end;

function TVizMod.VizSetContainerAlpha(  aLayer: Integer;
  aContainerName, aAlphaValue: string): Boolean;
begin
// if not tcpclnt.Connected then tcpclnt.Open; //FRONT_LAYER //BACK_LAYER
  tcpclnt.sendln('11 RENDERER'+VizRtLayers[aLayer]+'*TREE*@' + aContainerName + '*ALPHA*ALPHA SET ' + UTF8Encode(aAlphaValue), #0);
end;

function TVizMod.VizSetContainerPosition(  aLayer: Integer;
  aContainerName, aPositionValue: string): Boolean;
begin
//  if not tcpclnt.Connected then tcpclnt.Open; //FRONT_LAYER //BACK_LAYER
  tcpclnt.sendln('11 RENDERER'+VizRtLayers[aLayer]+'*TREE*@' + aContainerName + '*TRANSFORMATION*POSITION SET ' + UTF8Encode(aPositionValue), #0);
end;

function TVizMod.VizKeyValSet(  aLayer: Integer;
  aFieldName, aKeyName, aValue: string): Boolean;
begin
  TcpClnt.Sendln(
              '11 RENDERER' + VizRtLayers[aLayer] + '*TREE*@'+ aFieldName +'*ANIMATION*KEY*' +
                aKeyName +'*VALUE SET ' + aValue, #0);
end;

function TVizMod.VizClear(  aLayer: Integer): boolean;
begin
//   tcpclnt.Close;
//   if not tcpclnt.Connected then tcpclnt.Open;
      tcpclnt.sendln('3 RENDERER' + VizRtLayers[aLayer] + ' SET_OBJECT ', #0);
      tcpclnt.Sendln('14 RENDERER' + VizRtLayers[aLayer] + '*STAGE SHOW 0.0', #0);
end;




function TVizMod.VizReloadSceneInRender(  aLayer: integer; AScene: string): boolean;
begin
//  if not TcpClnt.Connected then TcpClnt.Connect;
  TcpClnt.sendln('11 SCENE*' + AScene + ' RELOAD', #0);
  TcpClnt.sendln('11 RENDERER' + VizRtLayers[aLayer] + ' SET_OBJECT SCENE*'+AScene, #0);
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE SHOW 0.0', #0);
end;

function TVizMod.VizActiveSet(  aLayer: Integer; aFieldName, aState : string): Boolean;
begin
  TcpClnt.sendln('1 RENDERER'+ VizRtLayers[aLayer] +'*TREE*@' + aFieldName + '*ACTIVE SET ' + aState, #0);
end;

function TVizMod.VizActiveSetPath(  aLayer: Integer;
  aFieldName, aState: string): Boolean;
begin
  TcpClnt.sendln('1 RENDERER'+ VizRtLayers[aLayer] +'*TREE*' + aFieldName + '*ACTIVE SET ' + aState, #0);
end;

function TVizMod.VizDirectorContinue(  aLayer : integer; aDirector: string): boolean;
begin
  if aDirector <> '' then
    aDirector := '*DIRECTOR*' + aDirector;
//  if not TcpClnt.Connected then TcpClnt.Open; //FRONT_LAYER //BACK_LAYER
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE' + aDirector + ' CONTINUE', #0);
end;

function TVizMod.VizSoftClipSetVideo(  aLayer : Integer; aFiledName, aVideoPathName : string ): Boolean;
begin
  TcpClnt.sendln('1 RENDERER'+VizRtLayers[aLayer]+'*TREE*@' + aFiledName +'*FUNCTION*SoftClip*clipFile SET ' + aVideoPathName,#0);
end;

function TVizMod.VizDirectorContinueREV(  aLayer : integer; aDirector: string): boolean;
begin
  if aDirector <> '' then
    aDirector := '*DIRECTOR*' + aDirector;
//  if not TcpClnt.Connected then TcpClnt.Open; //FRONT_LAYER //BACK_LAYER
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE' + aDirector + ' CONTINUE REVERSE', #0);
end;

function TVizMod.VizDirectorPause(  aLayer: integer; aDirector: string): boolean;
begin
  if aDirector <> '' then
    aDirector := '*DIRECTOR*' + aDirector;
//  if not TcpClnt.Connected then TcpClnt.Open; //FRONT_LAYER //BACK_LAYER
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE' + aDirector + ' STOP', #0)
end;

function TVizMod.VizDirectorSetTime(  aLayer: integer;
  aDirector, aTime: string): boolean;
var
  vDirector : string;
begin
  if aDirector <> '' then
    vDirector := '*DIRECTOR*' + aDirector
  else
    vDirector := '';
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE'+ vDirector + ' SHOW ' + aTime, #0);
end;

function TVizMod.VizSetSceneInRender(  aLayer : integer; AScene : string): boolean;
begin
  //if not TcpClnt.Connected then TcpClnt.Connect;
  TcpClnt.sendln('11 SCENE*' + AScene + ' LOAD', #0);
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE SHOW 0.0', #0);  
  TcpClnt.sendln('11 RENDERER' + VizRtLayers[aLayer] + ' SET_OBJECT SCENE*'+AScene, #0);
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE SHOW 0.0', #0);
end;


function TVizMod.VizTargaClipTimeSet(aTime: string): boolean;
begin
//
  TcpClnt.sendln('11 RENDERER*TARGA3200*CHANNEL*3*CLIP_CUE SET ' + aTime, #0);
end;

function TVizMod.VizTargaPause: boolean;
begin
//
  TcpClnt.sendln('11 RENDERER*TARGA3200*CHANNEL*3*CLIP_CONTROL PAUSE', #0);
end;

function TVizMod.VizTargaPlay: boolean;
begin
//
  TcpClnt.sendln('11 RENDERER*TARGA3200*CHANNEL*3*CLIP_CONTROL PLAY', #0);

end;

function TVizMod.VizTargaStop: boolean;
begin
//
  TcpClnt.sendln('11 RENDERER*TARGA3200*CHANNEL*3*CLIP_CONTROL STOP', #0);
end;

function TVizMod.VizTextUpdate(  aLayer: Integer;
  aFiledName, aFiledData: string): boolean;
begin
  TcpClnt.sendln('11 RENDERER'+VizRtLayers[aLayer]+'*TREE*@' + aFiledName + '*GEOM*TEXT SET ' + UTF8Encode(aFiledData), #0);
end;

function TVizMod.VizDirectorStart(  aLayer : integer; aDirector: string): boolean;
begin
  if aDirector <> '' then
    aDirector := '*DIRECTOR*' + aDirector;
//  if not TcpClnt.Connected then TcpClnt.Open; //FRONT_LAYER //BACK_LAYER
  TcpClnt.Sendln('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE' + aDirector + ' START', #0);
end;

function TVizMod.VizGeomUpdate(  aLayer: integer;
  aFieldName, aGeomPathName: string): boolean;
begin
  TcpClnt.Sendln('1 RENDERER*TREE*@' + aFieldName + '*GEOM SET ' + aGeomPathName, #0);
end;

function TVizMod.VizGetAllStopsByDirecor(alayer: Integer; aDirectorName: string): string;
var
  ans : string;
  List: TStringList;
  i : Integer;
begin
  List := TStringList.Create;
  ans := VizAns('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE*DIRECTOR*' + aDirectorName + '*EVENT GET');
//  '11 {28913 5.28000000000000 0
//       28914 9.30000000000000 0
//       28915 11.42000007629395 0
//       28916 16.71999931335449 0 28917 22.02000045776367 0 28918 24.13999938964844 0 28919 29.44000053405762 0 28920 32.61999893188477 0 28921 35.79999923706055 0 28922 37.90000152587891 0 } '

  if Pos('ERROR',ans) <> 0 then
  begin
    Result := 'Error';
    Exit;
  end;
//  '11 ERROR <RENDERER*MIDDLE_LAYER*STAGE*DIRECTOR*Default*EVENT GET > : 'Default': invalid director path'
  ans := Copy(ans, Pos('11 {',ans) + 4,Length(ans));
  ans := Copy(ans, 0, Pos('}',ans)-1);
  List.DelimitedText := ans;
  Result := '';
  i := 1;
  while i <= list.Count do
  begin
    Result := Result + List[i] + ' ';
    i := i + 3
  end;
  List.Free;
end;

function TVizMod.VizGetDirectorTime(aLayer: Integer; aDirector: string): string;
var
  ans : string;
begin
//
    ans := VizAns('11 RENDERER' + VizRtLayers[aLayer] + '*STAGE*DIRECTOR*' + aDirector + ' GET_TIMELINE');
    Result := Copy(ans, Pos('11 ',ans) + 3, length(ans)); 
end;

function TVizMod.VizGetLoadedSceneName(aLayer : Integer): string;
var
  ans : string;
begin
{
'11 Hostname:
 Nephilime-PC'#$A'IP Address:
  192.168.20.60'#$A'Port:
    6100'#$A'GH-Server:
       VizDbServer@192.168.12.66
        Version: 2.3.2.0'#$A#$A'
        Back Layer:          Empty'#$A'
          Middle Layer: SCENE*PT/080913/ship'#$A'
          Front Layer:  Empty'#$A#$A'Uptime:       00 days 03 hours 25 minutes'#$A
}



  ans := VizAns('11 MAIN*ONAIR GET_INFO');
  case aLayer of
  1:
    begin
      ans := Copy(ans, Pos('Back Layer:',ans) + 11,pos('Middle Layer:',ans) - 11 -  Pos('Back Layer:',ans));
      ans := Copy(ans,0,length(ans)-1);
      ans := StringReplace(ans,'SCENE*',' ',[]);
      ans := TrimLeft(ans);
      Result := ans;
    end;
  2:
    begin
      ans := Copy(ans, Pos('Middle Layer',ans) + 13,pos('Front Layer:',ans) - 13 -  Pos('Middle Layer',ans));
      ans := Copy(ans,0,length(ans)-1);
      ans := StringReplace(ans,'SCENE*',' ',[]);
      ans := TrimLeft(ans);
      Result := ans;
    end;
  3:
    begin
      ans := Copy(ans, Pos('Front Layer:',ans) + 12,pos('Uptime:',ans) - 12 -  Pos('Front Layer:',ans));
      ans := Copy(ans,0,length(ans)-2);
      ans := StringReplace(ans,'SCENE*',' ',[]);
      ans := TrimLeft(ans);
      Result := ans;
    end;

  end;
end;

function TVizMod.VizImageUpdate(  aLayer: integer;
  aFieldName, aFilePathName: string): boolean;
begin
  TcpClnt.sendln('1 RENDERER*TREE*@' + aFieldName + '*TEXTURE*IMAGE SET ' + UTF8Encode(aFilePathName) ,#0);
end;

end.
