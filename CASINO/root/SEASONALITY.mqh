#include  "MASTER_INDI.mqh"


extern bool         use_season_month = true;
DIRECTION JANUARY = SHORT;
DIRECTION FEBRUARY = LONG;
DIRECTION MARCH = NEUTRAL;
DIRECTION APRIL = LONG;
DIRECTION MAY = SHORT;
DIRECTION JUNE = NEUTRAL;
DIRECTION JULY = LONG;
DIRECTION AUGUST = NEUTRAL;
DIRECTION SEPTEMBER = LONG;
DIRECTION OCTOBER = NEUTRAL;
DIRECTION NOVEMBER = NEUTRAL;
DIRECTION DECEMBER = LONG;




class clsSeason : 
     public  clsMasterIndi
{
   public:
                      clsSeason(string strInputSymbol, int intInputTF);
                      ~clsSeason();
      //void            Updater(datetime time, bool preloop=false);
      bool            blSeasonMonthAllowed(datetime time, int type);
      
   protected:
      void            Oninit();
      
   private:
};

clsSeason::clsSeason (string strInputSymbol,int intInputTF):
        clsMasterIndi(strInputSymbol,intInputTF)
{
  this.Oninit();
}

void clsSeason::Oninit(void)
{

}

clsSeason::~clsSeason(void)
{}

bool clsSeason::blSeasonMonthAllowed(datetime time, int type)
{
    int month = TimeMonth(time);
    switch(month)
    {
         case 1 :
            if(type == 1)
            {
                 if(JANUARY == LONG || JANUARY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(JANUARY == SHORT || JANUARY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
         case 2 :
            if(type == 1)
            {
                 if(FEBRUARY == LONG || FEBRUARY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(FEBRUARY == SHORT || FEBRUARY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 3 :
            if(type == 1)
            {
                 if(MARCH == LONG || MARCH == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(MARCH == SHORT || MARCH == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 4 :
            if(type == 1)
            {
                 if(APRIL == LONG || APRIL == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(APRIL == SHORT || APRIL == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 5 :
            if(type == 1)
            {
                 if(MAY == LONG || MAY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(MAY == SHORT || MAY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 6 :
            if(type == 1)
            {
                 if(JUNE == LONG || JUNE == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(JUNE == SHORT || JUNE == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 7 :
            if(type == 1)
            {
                 if(JULY == LONG || JULY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(JULY == SHORT || JULY == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 8 :
            if(type == 1)
            {
                 if(AUGUST == LONG || AUGUST == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(AUGUST == SHORT || AUGUST == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 9 :
            if(type == 1)
            {
                 if(SEPTEMBER == LONG || SEPTEMBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(SEPTEMBER == SHORT || SEPTEMBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 10 :
            if(type == 1)
            {
                 if(OCTOBER == LONG || OCTOBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(OCTOBER == SHORT || OCTOBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
        case 11 :
            if(type == 1)
            {
                 if(NOVEMBER == LONG || NOVEMBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(NOVEMBER == SHORT || NOVEMBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
         case 12 :
            if(type == 1)
            {
                 if(DECEMBER == LONG || DECEMBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            if(type == 2)
            {
                 if(DECEMBER == SHORT || DECEMBER == NEUTRAL)
                 {
                     return(true);
                 }
            }
            break;
    }
    return(false);
}
  