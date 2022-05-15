extern int BackTestDataTZ = +2;
extern int LiveBrokerTZ = +2;

class clsSession
{
     public:
           clsSession();
           ~clsSession();
           bool    blLondonSession();
           bool    blNewYorkSession();
           bool    blTokyoSession();
           bool    blFridayClose();
           bool    blCheckSession(string strStartTime, string strEndTime);
           void    Oninit();
           
     protected:
           int    intSelectedTZ;
           
     private:
           string strLondonStartTime;  //HH:MM in reference to GMT+0
           string strLondonEndTime;    //HH:MM in reference to GMT+0
           string strNewYorkStartTime; //HH:MM in reference to GMT+0
           string strNewYorkEndTime;   //HH:MM in reference to GMT+0
           string strTokyoStartTime;   //HH:MM in reference to GMT+0
           string strTokyoEndTime;     //HH:MM in reference to GMT+0
           int    intLondonStartHour;
           int    intLondonStartMin;
           int    intLondonEndHour;
           int    intLondonEndMin;
           int    intNewYorkStartHour;
           int    intNewYorkStartMin;
           int    intNewYorkEndHour;
           int    intNewYorkEndMin;
           int    intTokyoStartHour;
           int    intTokyoStartMin;
           int    intTokyoEndHour;
           int    intTokyoEndMin;
};

clsSession::clsSession()
{
     this.strLondonStartTime  = "08:00";
     this.strLondonEndTime    = "17:00";
     this.strNewYorkStartTime = "13:00";
     this.strNewYorkEndTime   = "22:00";
     this.strTokyoStartTime   = "00:00";
     this.strTokyoEndTime     = "09:00";
     this.Oninit();
}

clsSession::~clsSession(void){}

bool clsSession::blFridayClose(void)
{
       datetime dt_current = TimeCurrent();
       //we switch from data source to GMT+0
       datetime dt_gmt_0   = dt_current - (this.intSelectedTZ*60*60);
       MqlDateTime gmt_0_struc;
       TimeToStruct(dt_gmt_0 ,gmt_0_struc); // GMT 0
       if(gmt_0_struc.day == 5 && gmt_0_struc.hour >= 20 && gmt_0_struc.min >= 0)
       {
           return(true);
       }
       return(false);
}

bool clsSession::blTokyoSession(void)
{
       datetime dt_current = TimeCurrent();
       //we switch from data source to GMT+0
       datetime dt_gmt_0   = dt_current - (this.intSelectedTZ*60*60);
       MqlDateTime gmt_0_struc;
       TimeToStruct(dt_gmt_0 ,gmt_0_struc); // GMT 0
       //if(gmt_0_struc.hour > this.intLondonStartHour
       if(gmt_0_struc.hour > this.intTokyoStartHour)
       {
           //check end hour
           if(gmt_0_struc.hour < this.intTokyoEndHour)
           {
               return(true);
           }
           if(gmt_0_struc.hour == this.intTokyoEndHour && gmt_0_struc.min <= this.intTokyoEndMin)
           {
               return(true);
           }
      }
      if(gmt_0_struc.hour == this.intTokyoStartHour && gmt_0_struc.min >= this.intTokyoStartMin)
      {
           //check end hour
           if(gmt_0_struc.hour < this.intTokyoEndHour)
           {
               return(true);
           }
           if(gmt_0_struc.hour == this.intTokyoEndHour && gmt_0_struc.min <= this.intTokyoEndMin)
           {
               return(true);
           }
      }
       return(false);
}

bool clsSession::blLondonSession(void)
{
    datetime dt_current = TimeCurrent();
    //we switch from data source to GMT+0
    datetime dt_gmt_0   = dt_current - (this.intSelectedTZ*60*60);
    MqlDateTime gmt_0_struc;
    TimeToStruct(dt_gmt_0 ,gmt_0_struc); // GMT 0
    //if(gmt_0_struc.hour > this.intLondonStartHour
    if(gmt_0_struc.hour > this.intLondonStartHour)
    {
        //check end hour
        if(gmt_0_struc.hour < this.intLondonEndHour)
        {
            return(true);
        }
        if(gmt_0_struc.hour == this.intLondonEndHour && gmt_0_struc.min <= this.intLondonEndMin)
        {
            return(true);
        }
   }
   if(gmt_0_struc.hour == this.intLondonStartHour && gmt_0_struc.min >= this.intLondonStartMin)
   {
        //check end hour
        if(gmt_0_struc.hour < this.intLondonEndHour)
        {
            return(true);
        }
        if(gmt_0_struc.hour == this.intLondonEndHour && gmt_0_struc.min <= this.intLondonEndMin)
        {
            return(true);
        }
   }
    return(false);
}

bool clsSession::blNewYorkSession(void)
{
    datetime dt_current = TimeCurrent();
    //we switch from data source to GMT+0
    datetime dt_gmt_0   = dt_current - (this.intSelectedTZ*60*60);
    MqlDateTime gmt_0_struc;
    TimeToStruct(dt_gmt_0 ,gmt_0_struc); // GMT 0
    //if(gmt_0_struc.hour > this.intLondonStartHour
    if(gmt_0_struc.hour > this.intNewYorkStartHour)
    {
        //check end hour
        if(gmt_0_struc.hour < this.intNewYorkEndHour)
        {
            return(true);
        }
        if(gmt_0_struc.hour == this.intNewYorkEndHour && gmt_0_struc.min <= this.intNewYorkEndMin)
        {
            return(true);
        }
   }
   if(gmt_0_struc.hour == this.intNewYorkStartHour && gmt_0_struc.min >= this.intNewYorkStartMin)
   {
        //check end hour
        if(gmt_0_struc.hour < this.intNewYorkEndHour)
        {
            return(true);
        }
        if(gmt_0_struc.hour == this.intNewYorkEndHour && gmt_0_struc.min <= this.intNewYorkEndMin)
        {
            return(true);
        }
   }
    return(false);
}

bool clsSession::blCheckSession(string strStartTime,string strEndTime)
{
     string sep=":";                
     ushort u_sep;     
     u_sep = StringGetCharacter(sep,0);         
     string start_arr[];
     string end_arr[];
     
     //SPLIT
     int size1 = StringSplit(strStartTime,u_sep,start_arr);
     int size2 =StringSplit(strEndTime,u_sep,end_arr);
     int StartHour = (int)start_arr[0];
     int StartMin  = (int)start_arr[1];
     int EndHour   = (int)end_arr[0];
     int EndMin    = (int)end_arr[1];
     
     datetime dt_current = TimeCurrent();
     //we switch from data source to GMT+0
     datetime dt_gmt_0   = dt_current - (this.intSelectedTZ*60*60);
     MqlDateTime gmt_0_struc;
     TimeToStruct(dt_gmt_0 ,gmt_0_struc); // GMT 0
     //if(gmt_0_struc.hour > this.intLondonStartHour
     if(gmt_0_struc.hour > StartHour)
     {
        //check end hour
        if(gmt_0_struc.hour < EndHour)
        {
            return(true);
        }
        if(gmt_0_struc.hour == EndHour && gmt_0_struc.min <= EndMin)
        {
            return(true);
        }
   }
   if(gmt_0_struc.hour == StartHour && gmt_0_struc.min >= StartMin)
   {
        //check end hour
        if(gmt_0_struc.hour < EndHour)
        {
            return(true);
        }
        if(gmt_0_struc.hour == EndHour && gmt_0_struc.min <= EndMin)
        {
            return(true);
        }
   }
   return(false);
}


void clsSession::Oninit(void)
{
     //split string to hour and min
     string sep=":";                
     ushort u_sep;     
     u_sep = StringGetCharacter(sep,0);         
     string london_start_arr[];
     string london_end_arr[];
     string newyork_start_arr[];
     string newyork_end_arr[];
     string tokyo_start_arr[];
     string tokyo_end_arr[];
     
     //LONDON SPLIT
     int size1 = StringSplit(this.strLondonStartTime,u_sep,london_start_arr);
     int size2 =StringSplit(this.strLondonEndTime,u_sep,london_end_arr);
     this.intLondonStartHour = (int)london_start_arr[0];
     this.intLondonStartMin  = (int)london_start_arr[1];
     this.intLondonEndHour   = (int)london_end_arr[0];
     this.intLondonEndMin    = (int)london_end_arr[1];
     
     //NEW YORK SPLIT
     int size3 = StringSplit(this.strNewYorkStartTime,u_sep,newyork_start_arr);
     int size4 = StringSplit(this.strNewYorkEndTime,u_sep,newyork_end_arr);
     this.intNewYorkStartHour = (int)newyork_start_arr[0];
     this.intNewYorkStartMin  = (int)newyork_start_arr[1];
     this.intNewYorkEndHour   = (int)newyork_end_arr[0];
     this.intNewYorkEndMin    = (int)newyork_end_arr[1];
     
     //TOKYO SPLIT
     int size5 = StringSplit(this.strTokyoStartTime,u_sep,tokyo_start_arr);
     int size6 = StringSplit(this.strTokyoEndTime,u_sep,tokyo_end_arr);
     this.intTokyoStartHour   = (int)tokyo_start_arr[0];
     this.intTokyoStartMin    = (int)tokyo_start_arr[1];
     this.intTokyoEndHour     = (int)tokyo_end_arr[0];
     this.intTokyoEndMin      = (int)tokyo_end_arr[1];
     
     this.intSelectedTZ = IsTesting() ? BackTestDataTZ : LiveBrokerTZ;
     
     if(size1 != 2 || size2 !=2 || size3 != 2 || size4 !=2 || size5 != 2 || size6 !=2)
     {
         Alert("Time Input Format Error, Please Key in Format of HH:MM instead");
     }
}