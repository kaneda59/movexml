unit mainmvxml;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  Xml.XMLIntf, Xml.XMLDoc, System.Variants, Winapi.ActiveX;

type
  TMoveXMLsrv = class(TService)
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
  private
    procedure ScanPath;
    function getPath(const filename: string): string;
    procedure Log(const _type, value: string);
    function CopyFileAcrossNetwork(source, dest: string): boolean;
    procedure InitPath;
    { Déclarations privées }
  public
    function GetServiceController: TServiceController; override;
    { Déclarations publiques }
  end;

var
  MoveXMLsrv: TMoveXMLsrv;
  path_source: string = '';
  path_dest : string = '';
  path_system: string = '';
  filename_log: string = '';
  log_active: Boolean = True;


implementation

{$R *.DFM}
  uses inifiles;


function Complete(const value: string; const end_: string): string;
begin
  result:= value;
  if result<>'' then
   if result[Length(Result)]<>end_ then
     result:= Result + end_;
end;

procedure TMoveXMLsrv.InitPath;
var ini: TIniFile;
begin
  path_system:= ExtractFilePath(ParamStr(0)) + 'system\';
  ForceDirectories(path_system);
  ini:= TIniFile.Create(path_system + 'movexml.ini');
  try
    path_source:= Complete(ini.ReadString('config', 'path_source', ExtractFilePath(ParamStr(0))), '\');
    path_dest  := Complete(ini.ReadString('config', 'path_dest', ExtractFilePath(ParamStr(0))), '\');
    log_active := ini.ReadBool('config', 'log', True);
  finally
    FreeAndNil(Ini);
  end;
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  MoveXMLsrv.Controller(CtrlCode);
end;

function TMoveXMLsrv.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

function TMoveXMLsrv.getPath(const filename: string): string;
var nRoot: IXMLNode;
    nDemande: IXMLNode;
    nProtocols: IXMLNode;
    nProtocol: IXMLNode;
    nPath: IXMLNode;
    Doc: IXMLDocument;
begin
  result:= '';
  try
    if FileExists(FileName) then
    begin
      CoInitialize(nil);
      Doc:= TXMLDocument.Create(nil);
      try
        Doc.Active:= True;
        Doc.LoadFromFile(filename);
        Doc.Active:= True;
        if Doc.Active then
        begin
          nRoot:= Doc.ChildNodes.FindNode('Message');
          if Assigned(nRoot) then
          begin
            nDemande:= nRoot.ChildNodes.FindNode('Demande');
            if Assigned(nDemande) then
            begin
              nProtocols:= nDemande.ChildNodes.FindNode('Protocoles');
              if Assigned(nProtocols) then
              begin
                nProtocol:= nProtocols.ChildNodes.FindNode('Protocole');
                if Assigned(nProtocol) then
                begin
                  nPath:= nProtocol.ChildNodes.FindNode('Path');
                  if Assigned(nPath) then
                    result:= varToStr(nPath.NodeValue);
                end
              end;
            end;
          end;
        end;
      finally
        Doc:= nil;
      end;
    end
    else Log('error', 'file xml : ' + filename + ' not found');
    if Result='' then
         Log('error', 'path not found in xml file')
    else Log('info', 'path found : ' + Result);
  except
    on E: Exception do
      Log('error', 'exception to find path : ' + e.Message);
  end;
end;

function UNCFileExits(FileName: string): boolean;
var
  SearchRec: TSearchRec;
begin
  if (FindFirst(FileName, faAnyFile, SearchRec) = 0) then
  begin
    FindClose(SearchRec);
    Result := True;
  end
  else
    Result := False;
end;

function TMoveXMLsrv.CopyFileAcrossNetwork(source, dest : string): boolean;
begin
  result:= False;
  try
    Log('info', Format('move file %s to %s', [source, dest]));
    Result:= MoveFileEx(PChar(source),PChar(dest),MOVEFILE_COPY_ALLOWED or MOVEFILE_WRITE_THROUGH);
    log('info', SysErrorMessage(getLastError));
  except
    on E: exception do
      Log('error', 'copy file impossible : ' + e.Message);
  end;
end;

procedure TMoveXMLsrv.Log(const _type, value: string);
var
  Log : Text;
begin
  outputdebugstring(pchar(_type + ' : ' + value));
  if log_active then
  begin
    AssignFile(Log,filename_log);
    if fileExists(filename_log) then
         Append(Log)
    else Rewrite(Log);
    WriteLn(Log, '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss', now) + '] : ' + _type + ' ' + value);
    Flush(Log);
    Close(Log);
  end;
end;

procedure TMoveXMLsrv.ScanPath;
var SR: TSearchRec;
    path: string;
    filexml: string;
begin
  if FindFirst(path_source + '*.ok', faAnyFile, SR)=0 then
  repeat
    filexml:= ChangeFileExt(path_source + SR.Name, '.xml');
    if FileExists(filexml) then
    begin
      Log('info', 'found xml file, scan path');
      path:= getPath(filexml);
      if path<>'' then
      begin
        if UNCFileExits(path) then
        begin
          Log('info', path + ' found and moved to ' + path_dest);
          if CopyFileAcrossNetwork(path, path_dest + ChangeFileExt(ExtractFileName(path), '.rtf')) then
          begin
            CopyFileAcrossNetwork(path_source + SR.Name, path_dest + SR.Name);
            CopyFileAcrossNetwork(filexml, path_dest + ExtractFileName(filexml));
          end;
        end
        else Log('error', 'file ' + path + ' not found');
      end;
    end;
  until FindNext(SR)<>0;
  FindClose(SR);
end;

procedure TMoveXMLsrv.ServiceExecute(Sender: TService);
const
  SecBetweenRuns = 10;
var
  Count: Integer;
begin
  Count := 0;
  while not Terminated do
  begin
    filename_log:= path_system + 'mvxml_' + FormatDateTime('yyyymmdd', Date) + '.log';
    Inc(Count);
    if Count >= SecBetweenRuns then
    begin
      Count := 0;
      ScanPath;
    end;
    Sleep(1000);
    ServiceThread.ProcessRequests(False);
  end;
end;

procedure TMoveXMLsrv.ServiceStart(Sender: TService; var Started: Boolean);
begin
  InitPath;
end;

end.
