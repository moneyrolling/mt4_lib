#import "wininet.dll"
#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100 // Forces the request to be resolved by the origin server, even if a cached copy exists on the proxy.
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000 // Does not add the returned entity to the cache. 
#define INTERNET_FLAG_RELOAD            0x80000000 // Forces a download of the requested file, object, or directory listing from the origin server, not from the cache.

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InternetOpenW(string sAgent,int lAccessType,string sProxyName,string sProxyBypass,int lFlags);
int InternetOpenUrlW(int    hInternetSession,string    sUrl,string    sHeaders="",int    lHeadersLength=0,int    lFlags=0,int    lContext=0);
int InternetReadFile(int hFile,uchar &sBuffer[],int lNumBytesToRead,int &lNumberOfBytesRead[]);
int InternetCloseHandle(int    hInet);

#import
bool bWinInetDebug=false;

int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig=0;
int Internet_Open_Type_Direct= 1;
int Internet_Open_Type_Proxy = 3;
int Buffer_LEN=80;

//JSON PARSING
#include "HASH.mqh"
#include "JSON.mqh"
//EUPORIA
//string default_gurl = "https://script.google.com/macros/s/AKfycbyrd3X0Y7ZKZx0iqP7Kf-O-2dOFE6yLc3yy1mWG16AXcmMNDg9-rOynaMfGkrat948s1w/exec?path=/direction/";
//EA LOCK
string account_gurl   = "https://script.google.com/macros/s/AKfycbxvitxz8WQVtnPv8wlvF4hggDSZ4bwcuUj-qwVg4RbVro7_8hy6N8f4ZluXOuLqB9M2_Q/exec?path=/accounts/";                         
string direction_gurl = "https://script.google.com/macros/s/AKfycbwPKl55DikQR9YP5qxQjyq4ra1ZCe0WbEsG3Sw409TJAYW6C-CbSygbh1cr3SkcI45Q/exec?path=/direction/";
//LYL

//string default_gurl = "https://script.google.com/macros/s/AKfycbzooxRMKYxbIJrU4cA8ldYQzRo0R2WubUl9eJ3lNMqtkDG5YZbC3-GYU1MYq-bLNnc/exec?path=/direction/";
                 
struct JSON_MESSAGE
{
    string   _symbol;
    string   _direction;
    int      _account;
    string   _broker;
    datetime _expiry;
    JSON_MESSAGE() : _symbol(""),_direction(""),_account(0),_broker(""),_expiry(0){};
};

class clsGsheet
{
     public:
         clsGsheet();
         clsGsheet(string strInpGURL, string strInpTag);
         ~clsGsheet();
         void   Oninit();
         //GET API
         void   Updater(string symbol);
         void   GetDirection(string symbol);
         void   CheckAccount(int intAccID);
         int    intDirection;
         
     protected:
         //DLL FUNCTION
         bool   GrabWeb(string strUrl,string &strWebPage);
         int    hSession(bool Direct);
         int    bytes;
         void   ParseJsonMessage(string strInpMessage, JSON_MESSAGE &OutMessage);
         bool   blCheckTimer();
         
     
     private:
         string strDirectionURL;
         string strAccountURL;
         bool   blBackTestMode;
         //IMPORT CLASS OBJECT
         JSONParser *parser;
         datetime dtTimer;
         int    intAPIRefreshInterval;
         
         
};

clsGsheet::clsGsheet()
{
     this.strDirectionURL = direction_gurl;
     strAccountURL = account_gurl;
     this.Oninit();
}

clsGsheet::clsGsheet(string strInpGURL, string strInpTag)
{ 
     this.strDirectionURL = strInpGURL +"?path=/"+strInpTag+"/";
     this.Oninit();
}

clsGsheet::~clsGsheet(void)
{
     if(CheckPointer(parser)==POINTER_DYNAMIC) delete parser;
}

void clsGsheet::Oninit(void)
{
     this.intAPIRefreshInterval = 60;
     parser = new JSONParser();
     if(!IsTesting())
     {
          this.blBackTestMode = false;
     }
     else
     {
          Print("BackTest Mode External Direction Not Applying");
     }
     if(!this.blBackTestMode)
     {
          //CHECK DLL ENABLE
          if(!IsDllsAllowed())
          {
              Alert("Please Allow DLL Import to Enable EA to Run Correctly");
              ExpertRemove();
          }
          CheckAccount(AccountNumber());
     }
     
     
}

bool clsGsheet::blCheckTimer()
{
    if(this.dtTimer == 0)
    {
       this.dtTimer = TimeCurrent();
       return(true);
    }
    else
    {
       if(TimeCurrent() - this.dtTimer >= this.intAPIRefreshInterval*60)
       {
           this.dtTimer = TimeCurrent();
           return(true);
       }
    }
    return(false);
}

void clsGsheet::Updater(string symbol)
{
    if(!IsTesting())
    {
        if(this.blCheckTimer())
        {
            this.GetDirection(symbol);
            Alert("Checking Direction of ",symbol);
            Alert("Final Direction is ",intDirection);
        }
    }
   
}

void clsGsheet::CheckAccount(int intAccID)
{
   string send_url = strAccountURL+(string)intAccID;
   string reply;
   this.GrabWeb(send_url,reply);
   //Alert("Reply is ",reply);
   JSON_MESSAGE out_msg;
   this.ParseJsonMessage(reply,out_msg);
   /*
   Alert("Account Retrieval number is ",out_msg._account);
   Alert("Broker is ",out_msg._broker);
   Alert("Expiry is ",out_msg._expiry);
   Alert("Server name is ",AccountServer());
   Alert("Broker Correct is ",out_msg._broker==AccountServer());
   Alert("Account Correct is ",out_msg._account==AccountNumber());
   Alert("Time Allowed is ",out_msg._expiry > TimeCurrent());
   */
   bool allowed = true;
   if(out_msg._account!=AccountNumber() && out_msg._broker!=AccountServer() && out_msg._expiry <= TimeCurrent())
   {
         Alert("No Account Info Stored, Kindly Contact admin@moneyrolling.top");
         allowed = false;
   }
   else
   {
      if(out_msg._account!=AccountNumber())
      {
          Alert("Wrong Account Attached, Kindly Contact admin@moneyrolling.top");
          allowed = false;
      }
      if(out_msg._broker!=AccountServer())
      {
          Alert("Wrong Broker Attached, Kindly Contact admin@moneyrolling.top");
          allowed = false;
      }
      if(out_msg._expiry <= TimeCurrent())
      {
          Alert("EA Subscription Expired, Kindly Contact admin@moneyrolling.top");
          allowed = false;
      }
   }
   if(!allowed) ExpertRemove();
}

void clsGsheet::GetDirection(string symbol)
{
   //RESET ON EACH RUN
   this.intDirection = 0;
   string reply;
   string send_url = direction_gurl+symbol;
   this.GrabWeb(send_url,reply);
   //Print("Reply is ",reply);
   JSON_MESSAGE out_msg;
   this.ParseJsonMessage(reply,out_msg);
   //Alert("Checking Symbol is ",symbol+"A");
   //Alert("Out Message Symbol is ",out_msg._symbol+"A");
   //Print("Out Message Direction is ",out_msg._direction);
   if(out_msg._symbol != symbol)
   {
       Print("Wrong Symbol Input / No Symbol In Database, revert to Default Option");
       this.intDirection = 0;
   }
   else
   {
       if(out_msg._direction == "LONG")    this.intDirection = 1;
       if(out_msg._direction == "SHORT")   this.intDirection = -1;
       if(out_msg._direction == "NEUTRAL") this.intDirection = 0;
       if(out_msg._direction == "STOP")    this.intDirection = 444;
   }
}

void clsGsheet::ParseJsonMessage(string strInpMessage, JSON_MESSAGE &OutMessage)
{
   JSONValue *jv = this.parser.parse(strInpMessage);
   if (jv == NULL) 
   {
        Print("error:"+(string)this.parser.getErrorCode()+this.parser.getErrorMessage());
   }
   else 
   {
        //Print("PARSED:"+jv.toString());
        if (jv.isObject())
        {
             //Print("Parsed Item Is An Object");
             JSONObject *jo = jv;
             JSONIterator *it = new JSONIterator(jo);
             int count = 0;
             string quote = CharToStr(0x22);
             for( ; it.hasNext() ; it.next()) 
             {
                 //Print("Current IT Key is ",it.key());
                 if(it.key()=="SYMBOL")
                 {
                     //Print("Quote is ",quote);
                     OutMessage._symbol = it.val().toString();
                     StringReplace(OutMessage._symbol,quote,"");
                 }
                 if(it.key()=="DIRECTION")
                 {
                     OutMessage._direction = it.val().toString();
                     StringReplace(OutMessage._direction,quote,"");
                 }
                 if(it.key()=="ACCOUNT")
                 {
                     string acc = it.val().toString();
                     StringReplace(acc,quote,"");
                     OutMessage._account = (int)StringToInteger(acc);
                 }
                 if(it.key()=="BROKER")
                 {
                     OutMessage._broker = it.val().toString();
                     StringReplace(OutMessage._broker,quote,"");
                 }
                 if(it.key()=="EXPIRY")
                 {
                     string expiry = it.val().toString();
                     StringReplace(expiry,quote,"");
                     OutMessage._expiry = StringToTime(expiry);
                 }
                 
             }
             delete it;
        }
        
        delete jv;
   } 
   
}


int clsGsheet::hSession(bool Direct)
{
   string InternetAgent;
   if(hSession_IEType==0)
     {
      InternetAgent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
      hSession_IEType = InternetOpenW(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
      hSession_Direct = InternetOpenW(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
     }
   if(Direct)
     {
      return(hSession_Direct);
     }
   else
     {
      return(hSession_IEType);
     }
}


bool clsGsheet::GrabWeb(string strUrl,string &strWebPage)
{
   bool   time_over=false;
   int    hInternet;
   int    iResult;
   int    lReturn[]= {1};
   uchar  sBuffer[1024];

   uint flags=INTERNET_FLAG_NO_CACHE_WRITE|INTERNET_FLAG_PRAGMA_NOCACHE|INTERNET_FLAG_RELOAD;

   hInternet=InternetOpenUrlW(hSession(false),strUrl,NULL,0,flags);
   //Print("Reading URL: "+strUrl);      //added by MN
   iResult=InternetReadFile(hInternet,sBuffer,Buffer_LEN,lReturn);
   strWebPage=CharArrayToString(sBuffer,0,lReturn[0]);
   uint init_time=GetTickCount();
   while(lReturn[0]!=0)
   {
      iResult=InternetReadFile(hInternet,sBuffer,Buffer_LEN,lReturn);
      if(lReturn[0]==0)
         break;
      this.bytes=this.bytes+lReturn[0];
      strWebPage=strWebPage+CharArrayToString(sBuffer,0,lReturn[0]);
      uint final_time=GetTickCount()-init_time;
      if(final_time>1000)
        {
         time_over=true;
         Print("Time Over : ",final_time," ms");
         break;
        }
     }
//Print("Closing URL web connection");   //added by MN
   iResult=InternetCloseHandle(hInternet);
   if(iResult == 0)
      return(false);
   if(time_over)
      return false;
   return(true);
}