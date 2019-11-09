program movexml;

uses
  Vcl.SvcMgr,
  mainmvxml in 'mainmvxml.pas' {MoveXMLsrv: TService};

{$R *.RES}

begin
  // Windows 2003 Server n�cessite que StartServiceCtrlDispatcher soit
  // appel� avant CoRegisterClassObject, qui peut �tre appel� indirectement
  // par Application.Initialize. TServiceApplication.DelayInitialize permet
  // l'appel de Application.Initialize depuis TService.Main (apr�s
  // l'appel de StartServiceCtrlDispatcher).
  //
  // L'initialisation diff�r�e de l'objet Application peut affecter
  // les �v�nements qui surviennent alors avant l'initialisation, tels que
  // TService.OnCreate. Elle est seulement recommand�e si le ServiceApplication
  // enregistre un objet de classe avec OLE et est destin�e � une utilisation
  // avec Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TMoveXMLsrv, MoveXMLsrv);
  Application.Run;
end.
