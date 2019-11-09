program movexml;

uses
  Vcl.SvcMgr,
  mainmvxml in 'mainmvxml.pas' {MoveXMLsrv: TService};

{$R *.RES}

begin
  // Windows 2003 Server nécessite que StartServiceCtrlDispatcher soit
  // appelé avant CoRegisterClassObject, qui peut être appelé indirectement
  // par Application.Initialize. TServiceApplication.DelayInitialize permet
  // l'appel de Application.Initialize depuis TService.Main (après
  // l'appel de StartServiceCtrlDispatcher).
  //
  // L'initialisation différée de l'objet Application peut affecter
  // les événements qui surviennent alors avant l'initialisation, tels que
  // TService.OnCreate. Elle est seulement recommandée si le ServiceApplication
  // enregistre un objet de classe avec OLE et est destinée à une utilisation
  // avec Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TMoveXMLsrv, MoveXMLsrv);
  Application.Run;
end.
