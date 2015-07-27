package com.backup42.desktop;

import com.backup42.common.AuthorityLocation;
import com.backup42.common.CPVersion;
import com.backup42.common.OrgType;
import com.backup42.common.User;
import com.backup42.common.config.CentralConfig;
import com.backup42.common.config.OrgTypeConfigItem;
import com.backup42.common.config.ServiceConfig;
import com.backup42.common.config.ServicePeerConfig;
import com.backup42.common.config.ServiceUIConfig;
import com.backup42.common.perm.C42PermissionPro;
import com.backup42.desktop.actions.ShowMainWindow;
import com.backup42.desktop.controllers.MainWindowController;
import com.backup42.desktop.events.service.ConnectFailedEvent;
import com.backup42.desktop.events.service.ConnectedEvent;
import com.backup42.desktop.interfaces.IModelObserver;
import com.backup42.desktop.layout.CPFormBuilder;
import com.backup42.desktop.layout.CPGridFormBuilder;
import com.backup42.desktop.layout.CPMigFormBuilder;
import com.backup42.desktop.model.AppModel;
import com.backup42.desktop.model.ConfigModel;
import com.backup42.desktop.model.LicenseModel;
import com.backup42.desktop.model.SystemModel;
import com.backup42.desktop.model.UserListModel;
import com.backup42.desktop.model.UserModel;
import com.backup42.desktop.utils.CPFont;
import com.backup42.desktop.utils.DesktopProperties;
import com.backup42.desktop.view.MainWindow;
import com.backup42.desktop.view.MainWindow.Event.AppActivatedEvent;
import com.backup42.desktop.view.MainWindow.Event.AppCloseEvent;
import com.backup42.desktop.view.MainWindow.Event.AppDeactivatedEvent;
import com.backup42.desktop.view.MainWindow.Event.AppShowEvent;
import com.backup42.desktop.view.MainWindow.Event.Listener;
import com.backup42.service.CPService;
import com.backup42.service.CPText;
import com.backup42.service.CpsFolders;
import com.backup42.service.ui.UIInfoUtility;
import com.backup42.service.ui.UIInfoUtility.UIConnectionDetailsResult;
import com.backup42.service.ui.message.StatusResponseMessage;
import com.backup42.service.ui.message.UpdateLicenseMessage;
import com.code42.auth.ILicense;
import com.code42.config.ConfigItem;
import com.code42.crypto.StringHasher;
import com.code42.event.IListener;
import com.code42.event.Listener;
import com.code42.event.Publisher;
import com.code42.i18n.LocaleUtil;
import com.code42.i18n.Text;
import com.code42.io.FileUtility;
import com.code42.lang.ClassPathHacker;
import com.code42.lang.NativeLibraryLoader;
import com.code42.logging.Layout42;
import com.code42.logging.LoggerFactory;
import com.code42.logging.SystemOut;
import com.code42.messaging.Location;
import com.code42.os.mac.io.FileManager;
import com.code42.os.mac.io.FileManager.FSCatalogInfo;
import com.code42.os.posix.PosixProcessCommands;
import com.code42.os.win.process.ProcessUtil;
import com.code42.perm.PermissionUtils;
import com.code42.swt.layout.FormBuilder;
import com.code42.swt.layout.GridFormBuilder;
import com.code42.swt.layout.MigFormBuilder;
import com.code42.swt.util.ActionManager;
import com.code42.swt.util.SWTExec;
import com.code42.swt.util.SWTPathUtil;
import com.code42.swt.view.AppWindowEvent.WindowReadyEvent;
import com.code42.utils.AppUtil;
import com.code42.utils.ArrayUtils;
import com.code42.utils.Formatter;
import com.code42.utils.LangUtils;
import com.code42.utils.Os;
import com.code42.utils.PropertiesUtil;
import com.code42.utils.Stopwatch;
import com.code42.utils.SystemProperties;
import com.code42.watcher.SystemWatcher;
import com.code42.xml.XmlTool;
import java.io.File;
import java.io.IOException;
import java.util.Locale;
import java.util.Properties;
import org.apache.log4j.Level;
import org.apache.log4j.PropertyConfigurator;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;

public class CPDesktop
  extends Publisher
  implements SplashWindow.Event.Listener, MainWindow.Event.Listener, IModelObserver
{
  private static final com.code42.logging.Logger log = LoggerFactory.getLogger(CPDesktop.class.getName());
  private static final Object MAIN_MONITOR = new Object[0];
  private static Display display;
  private SplashWindow splashWindow;
  private final Listener listener = new Listener(this);
  private Services services;
  private final Object[] connectMonitor = new Object[0];
  private final AppModel appModel;
  private static String appBaseName;
  private PropertiesUtil customProps;
  
  public static void main(String[] args)
    throws Throwable
  {
    try
    {
      Layout42.configureConsoleOnly(Level.INFO);
      
      String tmpdirname = System.getProperty("java.io.tmpdir");
      if (tmpdirname == null)
      {
        SystemOut.info(CPDesktop.class, "init", "No JVM temp directory configured!");
        System.exit(1);
      }
      File tmpdir = new File(tmpdirname);
      if (!tmpdir.exists())
      {
        SystemOut.info(CPDesktop.class, "init", "JVM temp directory " + tmpdirname + " does not exist!");
        System.exit(1);
      }
      if (!tmpdir.isDirectory())
      {
        SystemOut.info(CPDesktop.class, "init", "JVM temp directory " + tmpdirname + " is not a directory!");
        System.exit(1);
      }
      if (!tmpdir.canWrite())
      {
        SystemOut.info(CPDesktop.class, "init", "JVM temp directory " + tmpdirname + " exists but we can't write to it!");
        
        System.exit(1);
      }
      File swtDir = new File(tmpdirname + System.getProperty("file.separator") + ".cpswt");
      
      SystemProperties.setProperty("swt.library.path", swtDir.getAbsolutePath());
      String jvm = SystemProperties.getJvmDetails();
      String os = SystemProperties.getOsDetails();
      String user = System.getProperty("user.name") + ", " + System.getProperty("user.home");
      
      SystemOut.info(CPDesktop.class, "init", "*************************************************************");
      SystemOut.info(CPDesktop.class, "init", "*************************************************************");
      SystemOut.info(CPDesktop.class, "init", "STARTED " + getAppBaseName() + "Desktop");
      SystemOut.info(CPDesktop.class, "init", "CPVERSION = " + CPVersion.asString());
      SystemOut.info(CPDesktop.class, "init", "ARGS      = " + ArrayUtils.toString(args));
      SystemOut.info(CPDesktop.class, "init", "LOCALE    = " + Locale.getDefault().getDisplayName(Locale.ENGLISH));
      SystemOut.info(CPDesktop.class, "init", "JVM       = " + jvm);
      SystemOut.info(CPDesktop.class, "init", "OS        = " + os);
      SystemOut.info(CPDesktop.class, "init", "User      = " + user);
      SystemOut.info(CPDesktop.class, "init", "swt.library.path = " + System.getProperty("swt.library.path"));
      SystemOut.info(CPDesktop.class, "init", "*************************************************************");
      if (swtDir.exists())
      {
        File[] swtFiles = swtDir.listFiles();
        if (swtFiles != null) {
          for (File swtFile : swtFiles)
          {
            boolean deleted = swtFile.delete();
            if (deleted) {
              SystemOut.info(CPDesktop.class, "init", "SWT library deleted: " + swtFile);
            }
          }
        }
      }
      else
      {
        boolean swtDirCreated = swtDir.mkdir();
        if (swtDirCreated) {
          SystemOut.info(CPDesktop.class, "init", "SWT library dir created: " + swtDir);
        }
      }
      SWTPathUtil.addSwtToPath();
      AppTimer.begin(CPDesktop.class.getSimpleName());
      System.setProperty("file.encoding", "UTF-8");
      XmlTool.useInternalDocumentBuilderFactory();
      
      CPDesktop startupController = new CPDesktop(args);
      startupController.launch();
    }
    catch (Throwable e)
    {
      String msg = "Failed to launch " + CPDesktop.class.getSimpleName() + "; " + e;
      log.error(msg, new Object[] { e });
      SystemOut.log(Level.ERROR, CPDesktop.class, "init", msg);
      throw e;
    }
  }
  
  public static void secondaryMain(String[] args)
  {
    SystemOut.info(CPDesktop.class, "secondaryMain", "Bring main window forward.");
    Display disp = MainWindow.getInstance().getShell().getDisplay();
    ActionManager.run(disp, new ShowMainWindow());
  }
  
  public CPDesktop(String[] args)
    throws Exception
  {
    Properties commandLineArguments = AppUtil.getCommandLineProperties(args);
    
    AppTimer.begin("PreSplash");
    
    String waitValue = commandLineArguments.getProperty("waitForCustom");
    if (Boolean.valueOf(waitValue).booleanValue()) {
      waitForCustom();
    }
    customProps = new PropertiesUtil(new Properties());
    customProps.load(new File(CpsFolders.getCustomParent(appBaseName), "conf/custom.properties"), false);
    
    LangUtils.registerImpl(FormBuilder.class, CPFormBuilder.class);
    LangUtils.registerImpl(GridFormBuilder.class, CPGridFormBuilder.class);
    LangUtils.registerImpl(MigFormBuilder.class, CPMigFormBuilder.class);
    Text.setInstance(CPText.getTextInstance());
    Text.getInstance().setOverride(customProps.getProperties());
    
    String appName = CPText.getAppName();
    Display.setAppName(appName);
    
    String devConfigName = commandLineArguments.getProperty("devConfigName");
    if (SystemProperties.isDevEnv())
    {
      if (!LangUtils.hasValue(devConfigName)) {
        throw new Exception("Unable to start, missing devConfigName property.");
      }
      String appDataPath = SystemProperties.getOptional("c42.app.commonDataFolder");
      String skinPath = "skin";
      if (LangUtils.hasValue(devConfigName))
      {
        ServiceConfig sc = new ServiceConfig();
        String xml = FileUtility.readTextFile("../b42_service/conf/test/" + devConfigName + ".xml");
        sc.fromXml(xml);
        OrgType orgType = orgType.get();
        if (orgType.equals(OrgType.BUSINESS)) {
          skinPath = "skin_blue";
        } else if (orgType.equals(OrgType.ENTERPRISE)) {
          skinPath = "skin_black";
        }
      }
      File skinFolder = new File(skinPath);
      log.info("Skin folder: {}", new Object[] { skinFolder.getAbsolutePath() });
      ClassPathHacker.addFile(skinFolder);
      if (LangUtils.hasValue(appDataPath))
      {
        appDataPath = appDataPath + "/" + devConfigName;
        String absoluteAppDataPath = new File(appDataPath).getAbsolutePath();
        SystemProperties.setProperty("c42.app.commonDataFolder", absoluteAppDataPath);
      }
    }
    appModel = new AppModel(commandLineArguments);
    appModel.getConfigModel().addObserver(this);
    
    String servicePort = UIInfoUtility.getUIConnectionDetails().getPort();
    appModel.getDesktopProperties().setProperty("servicePort", servicePort);
    if (customProps.getOptionalBoolean("ssoAuth.enabled", false))
    {
      boolean required = customProps.getOptionalBoolean("ssoAuth.required", false);
      String provider = customProps.getOptional("ssoAuth.provider", "single sign-on");
      
      appModel.setupSso(required, provider);
    }
    String liblog = loadNativeLibraries();
    CpdFolders.init();
    CpdFoldersDeprecated.moveConfigFile();
    appModel.getDesktopProperties().loadMyProperties(CpdFolders.getConfFile());
    
    String localeString = appModel.getDesktopProperties().getLocale();
    Locale localle = setDefaultLocale(localeString, false);
    Text.getInstance().setUseNames(DesktopProperties.getInstance().isTextShowNames());
    
    String jvm = SystemProperties.getJvmDetails();
    String os = SystemProperties.getOsDetails();
    String user = System.getProperty("user.name") + ", " + System.getProperty("user.home");
    
    readLoggingConfiguration();
    log.info("*************************************************************");
    log.info("*************************************************************");
    log.info("STARTED " + getAppBaseName() + "Desktop - " + appModel.getDesktopProperties().getServicePort());
    log.info("CPVERSION = " + CPVersion.asString());
    log.info("ARGS      = " + ArrayUtils.toString(args));
    log.info("LOCALE    = " + localle.getDisplayName(Locale.ENGLISH));
    log.info("JVM       = " + jvm);
    log.info("OS        = " + os);
    log.info("User      = " + user);
    log.info(liblog);
    ClassPathHacker.logURLs(Level.INFO);
    
    appModel.getDesktopProperties().log();
    SystemProperties.dumpProperties(log.getName(), Level.INFO);
    log.info("*************************************************************");
    SystemProperties.logMemory("", Level.INFO);
    
    testNativeLibraries();
    XmlTool.log();
    
    display = Display.getDefault();
    
    CPFont.loadFonts(display, appModel.getDesktopProperties());
    
    StringHasher.C42.verifyMethodsExist(log);
    
    AppTimer.end("PreSplash");
    log.info("*************************************************************");
  }
  
  public static String getAppBaseName()
  {
    if (appBaseName == null) {
      appBaseName = SystemProperties.getOptional("appBaseName", "CrashPlan");
    }
    return appBaseName;
  }
  
  private void waitForCustom()
  {
    File customMark = new File(CpsFolders.getCustomParent(appBaseName), "~custom");
    SystemOut.info(CPDesktop.class, "waitForCustom", "Waiting for custom indicator to appear in " + customMark);
    try
    {
      Stopwatch sw = new Stopwatch();
      long maxWait = 10000L;
      while ((!customMark.exists()) && (sw.getElapsed() < 10000L)) {
        Thread.sleep(250L);
      }
      SystemOut.info(CPDesktop.class, "waitForCustom", "Waited " + Formatter.getDurationString(sw.getElapsed()) + " for custom indicator to appear in " + customMark + ", exists=" + customMark.exists());
    }
    catch (InterruptedException e)
    {
      SystemOut.info(CPDesktop.class, "waitForCustom", "InterruptedException while waiting for custom indicator to appear in " + customMark);
    }
  }
  
  private String loadNativeLibraries()
  {
    String libLog = null;
    try
    {
      libLog = NativeLibraryLoader.appendToPath();
    }
    catch (Exception e)
    {
      SystemOut.warning(CPService.class, "loadNativeLibraries", "Unable to load native libraries, exiting!", e);
      System.exit(1);
    }
    return libLog;
  }
  
  private void testNativeLibraries()
  {
    AppTimer.begin("testNativeLibraries");
    if ((SystemProperties.isOs(Os.Macintosh)) || (SystemProperties.isOs(Os.Linux)))
    {
      log.info("uid: " + PosixProcessCommands.getuid());
      log.info("gid: " + PosixProcessCommands.getgid());
      log.info("pid: " + PosixProcessCommands.getpid());
    }
    if (SystemProperties.isOs(Os.Macintosh))
    {
      File testFile = new File(appModel.getDesktopProperties().getLogPropertiesFile());
      FileManager fm = FileManager.getInstance();
      FileManager.FSCatalogInfo info = fm.getCatalogInfo(testFile);
      log.info("info: " + info);
    }
    if (SystemProperties.isOs(Os.Windows)) {
      log.info("pid: " + ProcessUtil.getProcessID());
    }
    AppTimer.end("testNativeLibraries");
  }
  
  private void launch()
    throws Exception
  {
    try
    {
      splashWindow = new SplashWindow(display);
      splashWindow.addListeners(new IListener[] { listener });
      splashWindow.open();
    }
    catch (Throwable e)
    {
      log.warn("Unable to show splash. " + e.getMessage(), new Object[] { e });
    }
    SystemWatcher.setCheckDelay(1000L);
    
    DesktopProperties props = appModel.getDesktopProperties();
    services = new Services(props.getServiceHost(), props.getServicePort());
    
    services.addListener(listener, ConnectedEvent.class);
    services.addListener(listener, ConnectFailedEvent.class);
    services.addListener(listener, StatusResponseMessage.class);
    
    Stopwatch sw = new Stopwatch();
    PermissionUtils.init(C42PermissionPro.permPackages);
    log.info("Loaded permissions in " + sw);
    
    log.info("Adding shutdown hook.");
    Runtime.getRuntime().addShutdownHook(new Thread()
    {
      public void run()
      {
        try
        {
          SystemOut.fine(getClass(), "run", "ShutdownHook...calling cleanup");
          
          CPDesktop.log.info("EXITING... Normally");
          services.stop();
          SystemWatcher.stop();
          SystemOut.fine(getClass(), "run", "ShutdownHook...sleeping 3 seconds");
          Thread.sleep(1000L);
          synchronized (CPDesktop.MAIN_MONITOR)
          {
            SystemOut.fine(getClass(), "run", "ShutdownHook...notify main of shutdown.");
            CPDesktop.MAIN_MONITOR.notifyAll();
          }
        }
        catch (InterruptedException e) {}
        SystemOut.fine(getClass(), "run", "ShutdownHook...calling halt.");
        
        Runtime.getRuntime().halt(0);
      }
    });
    connect(false);
    try
    {
      while (!display.isDisposed()) {
        try
        {
          if (!display.readAndDispatch()) {
            display.sleep();
          }
        }
        catch (Throwable e)
        {
          log.warn(e.toString(), new Object[] { e });
          display.sleep();
        }
      }
    }
    finally
    {
      SWTExec.shutdown();
      System.exit(0);
    }
  }
  
  private void connect(final boolean retry)
  {
    Thread thread = new Thread("connect")
    {
      public void run()
      {
        if (retry)
        {
          CPDesktop.log.info("Restarting service...");
          splashWindow.showConnectingMessage();
        }
        String host = appModel.getDesktopProperties().getServiceHost();
        int port = appModel.getDesktopProperties().getServicePort();
        long delay = appModel.getDesktopProperties().getConnectRetryDelay();
        long retryAttempts = appModel.getDesktopProperties().getConnectRetryAttempts();
        long attempts = retryAttempts + 1L;
        CPDesktop.log.info("Connecting to service at " + new Location(host, port));
        synchronized (connectMonitor)
        {
          connectionWait(700L);
          for (int i = 1; i <= attempts; i++)
          {
            if (i > 1)
            {
              CPDesktop.log.info("    FAILED on attempt #" + (i - 1) + ", retrying in " + delay + "ms");
              connectionWait(delay);
            }
            try
            {
              services.connect();
              
              connectionWait(30000L);
            }
            catch (IOException e)
            {
              CPDesktop.log.warn("Unable to establish connection.", new Object[] { e });
              break;
            }
            if (services.isConnected())
            {
              CPDesktop.log.info("    SUCCESS on attempt #" + i);
              break;
            }
            if (services.isConnecting())
            {
              CPDesktop.log.warn("    FAILED on attempt #" + i + ", aborting because something is seriously wrong.");
              break;
            }
            if (i == attempts) {
              CPDesktop.log.info("    FAILED on attempt #" + i + ", done");
            }
          }
          if (!services.isConnected()) {
            splashWindow.showConnectFailedMessage();
          }
        }
      }
      
      private void connectionWait(long delay)
      {
        try
        {
          connectMonitor.wait(delay);
        }
        catch (InterruptedException ie)
        {
          Thread.interrupted();
          CPDesktop.log.error("Interrupted while waiting to connect!");
        }
      }
    };
    thread.setDaemon(true);
    thread.start();
  }
  
  public void handleEvent(ConnectFailedEvent event)
  {
    synchronized (connectMonitor)
    {
      connectMonitor.notifyAll();
    }
  }
  
  public void handleEvent(ConnectedEvent event)
  {
    log.info("  Connected to service");
    services.getApplicationStatus();
    synchronized (connectMonitor)
    {
      connectMonitor.notifyAll();
    }
  }
  
  public void handleModelUpdate(ConfigModel model)
  {
    String locale = appModel.getDesktopProperties().getLocale();
    String localeConfig = (String)getConfigserviceUI.locale.getValue();
    if (!LangUtils.equals(locale, localeConfig)) {
      appModel.getDesktopProperties().setLocale(localeConfig);
    }
  }
  
  private Locale setDefaultLocale(String confLocale, boolean loggable)
  {
    if (LangUtils.hasValue(confLocale))
    {
      Locale locale = LocaleUtil.getLocale(confLocale);
      if (locale != null)
      {
        String msg = "Set Language Locale to " + confLocale;
        if (loggable) {
          log.info(msg);
        } else {
          SystemOut.info(getClass(), "setDefaultLocale", msg);
        }
        Locale.setDefault(locale);
        CPText.clearInstance();
        Text.setInstance(CPText.getTextInstance());
        if (AppModel.getInstance().getOrgType() != null) {
          CPText.setOrgType(AppModel.getInstance().getOrgType());
        }
        Text.getInstance().setOverride(customProps.getProperties());
        Text.getInstance().setUseNames(DesktopProperties.getInstance().isTextShowNames());
        return locale;
      }
    }
    return Locale.getDefault();
  }
  
  public void handleEvent(StatusResponseMessage event)
  {
    log.info("  Initial application state received");
    UpdateLicenseMessage lm = event.getLicenseMessage();
    ILicense lic = lm.getLicense();
    boolean authenticated = lm.isAuthenticated();
    appModel.setFirstInstall(!authenticated);
    appModel.setReauthorizeError(event.getReauthorizeError());
    appModel.getLicenseModel().setLicense(lic, authenticated, event.getUser().getUsername(), lm.getPassword(), lm.getAuthorizeRules(), lm.isBlocked());
    
    appModel.getSystem().setSecurityKey(lm.getSecurityKeyType(), lm.isDataKeyExists(), lm.isSecureDataKeyExists(), lm.getSecureDataKeyQA(), lm.getCustomKey());
    
    appModel.getSystem().setServiceOs(event.getOs());
    appModel.getSystem().setMacRootVolumeName(event.getMacRootVolumeName());
    appModel.setOrgType(event.getOrgType());
    SystemModel.getInstance().setDefaultRestorePath(event.getDefaultRestoreFolder());
    if (event.getUser() != null)
    {
      appModel.getUsers().setMyUser(event.getUser());
      
      String username = appModel.getUsers().getMyUser().getUsername();
      if (AuthorityLocation.isMissingParam(username))
      {
        String usernameProp = SystemProperties.getOptional("user.name");
        username = AuthorityLocation.parseString(username, usernameProp);
        appModel.getUsers().getMyUser().getUserObject().setUsername(username);
      }
    }
    String currentLocale = appModel.getDesktopProperties().getLocale();
    if (!LangUtils.equals(currentLocale, event.getLocale()))
    {
      appModel.getDesktopProperties().setLocale(event.getLocale());
      setDefaultLocale(event.getLocale(), true);
    }
    if (LangUtils.hasValue(event.getPassword()))
    {
      appModel.getConfigModel().getConfig().serviceUI.autoLogin.setValue(Boolean.valueOf(true));
      appModel.getConfigModel().getConfig().serviceUI.autoLoginPasswordHash.setValue(event.getPassword());
    }
    appModel.getConfigModel().getConfig().servicePeer.authority.setValue(event.getAuthority());
    if (LangUtils.hasValue(event.getWebsiteHost())) {
      appModel.getConfigModel().getConfig().servicePeer.centralConfig.websiteHost.setValue(event.getWebsiteHost());
    }
    if (event.isUpgrading()) {
      splashWindow.showUpgrading();
    } else {
      createMainWindow();
    }
  }
  
  private void createMainWindow()
  {
    display.asyncExec(new Runnable()
    {
      public void run()
      {
        CPDesktop self = CPDesktop.this;
        MainWindow mainWindow = new MainWindow(CPDesktop.display, appModel, services);
        mainWindow.addListener(listener, new Class[] { MainWindow.Event.AppCloseEvent.class, MainWindow.Event.AppShowEvent.class, AppWindowEvent.WindowReadyEvent.class });
        
        new MainWindowController(mainWindow, appModel, services);
      }
    });
  }
  
  public void handleEvent(AppWindowEvent.WindowReadyEvent event)
  {
    if (!splashWindow.isDisposed()) {
      splashWindow.close();
    }
  }
  
  private void readLoggingConfiguration()
  {
    log.trace("BackupService", new Object[] { "readLoggingConfiguration" });
    
    DesktopProperties appProps = appModel.getDesktopProperties();
    Properties logProps = new Properties();
    PropertiesUtil.load("conf/ui.log.properties", logProps);
    PropertiesUtil.load(appProps.getLogPropertiesFile(), logProps, false);
    
    String pattern = "log4j.appender.FILE.File";
    String patternProp = logProps.getProperty("log4j.appender.FILE.File");
    if ((!LangUtils.hasValue(patternProp)) || ("log/ui.log".equals(patternProp)))
    {
      String logfile = CpdFolders.getLogFile();
      SystemOut.info(CPDesktop.class, "readLoggingConfiguration", "Log file: " + logfile);
      logProps.setProperty("log4j.appender.FILE.File", logfile);
    }
    org.apache.log4j.Logger rootLogger = org.apache.log4j.Logger.getRootLogger();
    rootLogger.removeAllAppenders();
    PropertyConfigurator.configure(logProps);
  }
  
  public void handleEvent(SplashWindow.Event.RetryEvent event)
  {
    connect(true);
  }
  
  public void handleEvent(MainWindow.Event.AppShowEvent event)
  {
    services.removeAlert("");
  }
  
  public void handleEvent(MainWindow.Event.AppCloseEvent event) {}
  
  public void handleEvent(MainWindow.Event.AppActivatedEvent event) {}
  
  public void handleEvent(MainWindow.Event.AppDeactivatedEvent event) {}
  
  public static void setupTestApp()
  {
    LangUtils.registerImpl(FormBuilder.class, CPFormBuilder.class);
    LangUtils.registerImpl(GridFormBuilder.class, CPGridFormBuilder.class);
    LangUtils.registerImpl(MigFormBuilder.class, CPMigFormBuilder.class);
    Text.setInstance(CPText.getTextInstance());
    new AppModel();
    CPFont.loadFonts(Display.getDefault(), new Properties());
  }
  
  public static void close()
  {
    if (!display.isDisposed()) {
      display.close();
    }
  }
}

/* Location:
 * Qualified Name:     com.backup42.desktop.CPDesktop
 * Java Class Version: 6 (50.0)
 * JD-Core Version:    0.7.1
 */