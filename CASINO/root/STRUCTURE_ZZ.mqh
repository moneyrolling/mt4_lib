#include  "MASTER_INDI.mqh"
extern int LOOKBACK = 300;

struct STRUCTPHASE
{
   int      _trend; // 1 bull, 2 bear
   int      _latest_peak_idx;
   int      _latest_peak_support_idx;
   int      _latest_crest_idx;
   int      _latest_crest_resistance_idx;
   int      _leg_idx;
   STRUCTPHASE() : _trend(0), _latest_peak_idx(0), _latest_peak_support_idx(0), _latest_crest_idx(0), _latest_crest_resistance_idx(0) {};
};

struct STRUCTWAVE
{
   STRUCTPHASE _phase_list[];
   //STRUCTWAVE() : {};
};

class clsStructure : 
     public  clsMasterIndi
{
   public:
                      clsStructure(string strInputSymbol, int intInputTF, bool fibo_call=false);
                      ~clsStructure();
      void            Updater(datetime time, bool preloop=false);
      bool            EA_MODE;
      int             intTrend;
      double          dblZZ[];
      int             intPeakIndex[];
      int             intCrestIndex[];
      double          dblPeak[];
      double          dblCrest[];
      int             intLastStopIdx;
      int             intLatestPeakIdx;
      int             intLatestPeakSupportIdx;
      int             intLatestCrestIdx;
      int             intLatestCrestResistanceIdx;
      STRUCTWAVE      STRWaveList[];
      //VARIABLES TO BE CALLED
      int             intFinalDirection;
      int             intLeg;
      
   
   protected:
      void            Oninit();
      void            StorePhase(STRUCTPHASE &list[], STRUCTPHASE &structphase);
      void            StorePhaseToWave(STRUCTWAVE &wave_list[], STRUCTPHASE &phase_list[]);
      void            GetFinalDirection();
   
   private:
      string          strIdentifier;
      void            StoreZZ(int bar);
      void            FindStructure();
      int             intStructureFractalIndex(int start_idx, int &final_trend, STRUCTPHASE &phase_list[]);
      
       

};

clsStructure::clsStructure(string strInputSymbol,int intInputTF, bool fibo_call=false):
        clsMasterIndi(strInputSymbol,intInputTF)
     {
        Print("Constructor at Child ",strInputSymbol);
        //this.CALL_FROM_FIBO = fibo_call;
        this.Oninit();
     }
 
clsStructure::~clsStructure()
{
     
}

void clsStructure::Updater(datetime time,bool preloop=false)
{
   //Alert("Creating Label at ",this.intPeriod);
   int latest_bar = iBarShift(this.strSymbol,this.intPeriod,time);
   StoreZZ(latest_bar);
   FindStructure();
}

void clsStructure::Oninit(void)
{
    this.strIdentifier = this.strSymbol+"STR"+(string)this.intPeriod;
    this.EA_MODE = False;
    
}

void clsStructure::StoreZZ(int bar)
{
   ArrayFree(dblZZ);
   ArrayFree(dblPeak);
   ArrayFree(dblCrest);
   //ArrayFree(intPeakIndex);
   //ArrayFree(intCrestIndex);
   for(int i = bar + LOOKBACK; i > bar; i--)
   {
       int zz_size = ArraySize(dblZZ);
       double zz = iCustom(strSymbol,intPeriod,"ZigZag",5,5,3,0,i);
       if(zz != 0)
       {
            ArrayResize(dblZZ,zz_size+1);
            ArrayCopy(dblZZ,dblZZ,1,0);
            dblZZ[0] = zz;
            double high = iHigh(strSymbol,intPeriod,i);
            double low  = iLow(strSymbol,intPeriod,i);
            ArrayResize(dblPeak,zz_size+1);
            ArrayCopy(dblPeak,dblPeak,1,0);
            ArrayResize(dblCrest,zz_size+1);
            ArrayCopy(dblCrest,dblCrest,1,0);
            ArrayResize(intPeakIndex,zz_size+1);
            ArrayCopy(intPeakIndex,intPeakIndex,1,0);
            ArrayResize(intCrestIndex,zz_size+1);
            ArrayCopy(intCrestIndex,intCrestIndex,1,0);
            dblPeak[0]  = high == zz ? high : 0;
            dblCrest[0] = low  == zz ? low  : 0;
            intPeakIndex[0]  = high == zz ? i : 0;
            intCrestIndex[0] = low  == zz ? i  : 0;
       }
   }
}

void clsStructure::FindStructure()
{
   for(int i = ArraySize(dblPeak) - 2; i>= 0; i--)
   {  
       int check_idx = i;
       STRUCTPHASE new_phase_list[];
       int next_idx = intStructureFractalIndex(check_idx,intTrend,new_phase_list);
       //Alert("Post Store Phase size is ",ArraySize(new_phase_list));
       //store phase according to wave
       if(ArraySize(new_phase_list) > 0) StorePhaseToWave(STRWaveList,new_phase_list);
       
       //Alert("Post Store Wave Phase size is ",ArraySize(STRWaveList[0]._phase_list));
       if(next_idx < i)
       {
           i = next_idx;
           intLastStopIdx = i;
           
       } 
       else
       {
           intLastStopIdx = i;
           
           //Alert("Final idx is ",i);
           break;
       }
       
   }
}


int clsStructure::intStructureFractalIndex(int start_idx, int &final_trend, STRUCTPHASE &phase_list[])
{
   Alert("Starting Array idx is ",start_idx);
   
   int    cur_trend   = 8;
   bool   first_run   = true;
   double latest_high   = DBL_MIN;
   double latest_high_support = 0;
   double latest_low    = DBL_MAX;
   double latest_low_resistance = 0;
   double prev_high   = 0;
   double prev_high_support = 0;
   double prev_low    = 0;
   double prev_low_resistance = 0;
   int    end_idx = start_idx;
   if(start_idx <= 2) 
   {  
     Alert("Quit");
     return(end_idx);
   }
   ArrayFree(phase_list);
   for(int i = start_idx - 2; i>= 0; i--)
   {
        if(first_run)
        {
            if(dblPeak[i]  != 0) latest_high = dblPeak[i];
            if(dblCrest[i] != 0) latest_low  = dblCrest[i];
            first_run = false;
        }
        else
        {
            if(dblPeak[i] != 0)
            {    //PEAK IN CHARGE
                 if(cur_trend == 1 || cur_trend == 0 || cur_trend == 8)
                 {
                    if(
                         dblPeak[i] != 0 &&
                         dblPeak[i] > latest_high
                      )
                    {    //continuation of trend
                         
                         //1. Update previous saved value
                         prev_high   = latest_high;
                         prev_high_support = latest_high_support;
                         
                         latest_high = dblPeak[i];
                         //find new support
                         latest_high_support = dblCrest[i+1]; 
                         cur_trend = 1;
                         end_idx   = i;
                         //UPDATE INDEX
                         intLatestPeakIdx = intPeakIndex[i];
                         intLatestPeakSupportIdx = intCrestIndex[i+1];
                    }
                 }
                 if(cur_trend == -1)
                 {
                     if(
                         latest_low_resistance != 0 &&
                         dblPeak[i] > latest_low_resistance
                       )
                     {
                         prev_high   = latest_high;
                         prev_high_support = latest_high_support;
                         latest_high = dblPeak[i];
                         latest_high_support = dblCrest[i+1]; 
                         cur_trend = 0; //BOS
                         end_idx   = i;
                         //UPDATE INDEX
                         intLatestPeakIdx = intPeakIndex[i];
                         intLatestPeakSupportIdx = intCrestIndex[i+1];
                     }
                 }
            }
            
            else if(dblCrest[i] != 0)
            {    //CREST IN CHARGE
                 if(cur_trend == -1 || cur_trend == 0 || cur_trend == 8)
                 {
                    
                    if(
                        dblCrest[i] < latest_low
                      )
                    {  
                          //continuation of trend
                         prev_low   = latest_low;
                         prev_low_resistance = latest_low_resistance;
                         latest_low = dblCrest[i];
                         //find new resistance
                         latest_low_resistance = dblPeak[i+1]; 
                         cur_trend = -1;
                         end_idx   = i;
                         //Alert("i is ",i);
                         //cur_trend = intCrestIndex[i];
                         //UPDATE INDEX
                         intLatestCrestIdx = intCrestIndex[i];
                         intLatestCrestResistanceIdx = intPeakIndex[i+1];
                    }
                 }
                 if(cur_trend == 1)
                 {
                     if(
                         latest_high_support != 0 &&
                         dblCrest[i] < latest_high_support
                       )
                     {
                         prev_low   = latest_low;
                         prev_low_resistance = latest_low_resistance;
                         latest_low = dblCrest[i];
                         latest_low_resistance = dblPeak[i+1]; 
                         cur_trend = 0; //BOS
                         end_idx   = i;
                         //UPDATE INDEX
                         intLatestCrestIdx = intCrestIndex[i];
                         intLatestCrestResistanceIdx = intPeakIndex[i+1];
                        
                     }
                 }
            }
            
        }
        if(cur_trend != 8 && i >= end_idx)
        //if( i >= end_idx)
        {
           
           int sequence_size = ArraySize(phase_list);
           if(sequence_size == 0)
           {
              
              ArrayResize(phase_list,1);
              phase_list[0]._trend = cur_trend;
              phase_list[0]._latest_peak_idx = intLatestPeakIdx;
              phase_list[0]._latest_peak_support_idx = intLatestPeakSupportIdx;
              phase_list[0]._latest_crest_idx = intLatestCrestIdx;
              phase_list[0]._latest_crest_resistance_idx = intLatestCrestResistanceIdx;
           }
           else
           {
              //if(phase_list[0]._trend != cur_trend)
              //{
                  STRUCTPHASE new_phase;
                  new_phase._trend = cur_trend;
                  new_phase._latest_peak_idx = intLatestPeakIdx;
                  new_phase._latest_peak_support_idx = intLatestPeakSupportIdx;
                  new_phase._latest_crest_idx = intLatestCrestIdx;
                  new_phase._latest_crest_resistance_idx = intLatestCrestResistanceIdx;
                  new_phase._leg_idx = cur_trend == 1 ? intLatestPeakIdx : intLatestCrestIdx;
                  StorePhase(phase_list,new_phase);
              //}
           }
       }
   }
   final_trend = cur_trend;
   Alert("Final Trend is ",final_trend);
   return(end_idx);
}

void clsStructure::StorePhase(STRUCTPHASE &list[], STRUCTPHASE &structphase)
{
    int size = ArraySize(list);
    STRUCTPHASE new_list[];
    ArrayResize(new_list,size+1);
    for(int i = size; i >= 1; i--)
    {
         new_list[i] = list[i-1];
    }
    ArrayFree(list);
    ArrayResize(list,size+1);
    for(int i = size; i >= 1; i--)
    {
         list[i] = new_list[i];
    }
    list[0] = structphase;
}

void clsStructure::StorePhaseToWave(STRUCTWAVE &wave_list[], STRUCTPHASE &phase_list[])
{
    int wave_size = ArraySize(wave_list);
    STRUCTWAVE new_wave_list[];
    ArrayResize(new_wave_list,wave_size+1);
    for(int i = wave_size; i >= 1; i--)
    {
         new_wave_list[i] = wave_list[i-1];
    }
    ArrayFree(wave_list);
    ArrayResize(wave_list,wave_size+1);
    for(int i = wave_size; i >= 1; i--)
    {
         wave_list[i] = new_wave_list[i];
    }
    //copy phase into latest wave
    ArrayFree(wave_list[0]._phase_list);
    ArrayResize(wave_list[0]._phase_list,ArraySize(phase_list));
    for(int i = 0; i < ArraySize(phase_list); i++)
    {
        wave_list[0]._phase_list[i] = phase_list[i];
    }
}

void clsStructure::GetFinalDirection()
{ 
    //SUPER BULL  3, MEDIUM BULL 2,  WEAK BULL 1 
    //SUPER BEAR -3, MEDIUM BEAR -2, WEAK BEAR -1
    int size = ArraySize(STRWaveList);
    if(size <= 1)
    {
         intFinalDirection = STRWaveList[0]._phase_list[0]._trend == 1 ? 2 : -2;
         
    }
    else
    {
         if(STRWaveList[0]._phase_list[0]._trend == STRWaveList[1]._phase_list[0]._trend)
         {
              //intFinalDirection = STRWaveList[0]._phase_list[0]._trend
         }
    }
}




