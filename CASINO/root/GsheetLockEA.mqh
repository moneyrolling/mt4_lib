//+------------------------------------------------------------------+
//|                                                 GsheetLockEA.mqh |
//|                           Copyright 2020, MQL Developer Thailand |
//|                             https://www.facebook.com/mqldevthai/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MQL Developer Thailand"
#property link      "https://www.facebook.com/mqldevthai/"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string googlesheeturl;
void oninit(string gsheet_url)
  {
   googlesheeturl=gsheet_url;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int days_bars_count=iBars(Symbol(),PERIOD_D1);
int lastdaybars_count;
void ontick(string indicator_shorname="")
  {
   if(lastdaybars_count!=days_bars_count)
     {
      //if(!IsConnected())
      //  Sleep(1000);
      int len=StringLen(indicator_shorname);
      string reply;
      int acc=AccountNumber();
      if(acc==0)
         return;
      string send=googlesheeturl+"?path=/product/"+(string)acc;
      GrabWeb(send,reply);
      //Print(reply);
      if(StringFind(reply,"error")>=0)
        {
         Alert("Your Account not recognise. Please contact your admin");
         if(len==0)
            ExpertRemove();
         else
           {
            int sub_window=ChartWindowFind();
            ChartIndicatorDelete(0,sub_window,indicator_shorname);
           }
        }

      int startposactive=StringFind(reply,"active");
      string getreply=StringSubstr(reply,startposactive+8,1);
      //Print(getreply);
      if(getreply=="0")
        {
         Alert("Your Account are disable. Please contact your admin");
         if(len==0)
            ExpertRemove();
         else
           {
            int sub_window=ChartWindowFind();
            ChartIndicatorDelete(0,sub_window,indicator_shorname);
           }
        }
      else
         if(getreply=="1")
           {
            int startpost=StringFind(reply,"name");
            if(startpost>0)
            {
            int endpost=StringFind(reply,"\"",startpost+9);

            string name=StringSubstr(reply,startpost+7,endpost-startpost-7);
            //Print(name);
            Print(StringFormat("Hi ' %s ' good to see you again. Thank you choose our service",name));
            }else
               {
                 Print("Hi good to see you again. Thank you choose our service");
               }
           }
         else
           {
            Alert("Your Account not recognise. Please contact your admin");
            if(len==0)
               ExpertRemove();
            else
              {
               int sub_window=ChartWindowFind();
               ChartIndicatorDelete(0,sub_window,indicator_shorname);
              }
           }
      lastdaybars_count=days_bars_count;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |{"error":"Record not found [id=51612036]"}
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int hSession(bool Direct)
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int    bytes;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GrabWeb(string strUrl,string &strWebPage)
  {
   bool   time_over=false;
   int    hInternet;
   int      iResult;
   int    lReturn[]= {1};
   uchar sBuffer[1024];

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
      bytes=bytes+lReturn[0];
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
//+------------------------------------------------------------------+
