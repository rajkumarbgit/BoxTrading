
#include <Object.mqh>
#include <Trade/Trade.mqh>
input double RiskPercent = 0.5; 
input double MartingaleFactor =2.0;
input double TpPercent = 0.5;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int MinRangeBars = 20;
input int ComparisonBars = 40;
input double MinRangeFactor = 0.5;
class CSetup: public CObject{
   public:
      ulong posTicket;
      double lostMoney;
      datetime time1;
      datetime timeX;
      double high;
      double low;
      
   void drawRect(){
      string objName = MQLInfoString (MQL_PROGRAM_NAME)+" "+TimeToString(time1);
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time1, high, timeX, low);
      }
};
CSetup setup;
CTrade trade;

int OnInit(){
   return(INIT_SUCCEEDED);
}

void OnDeinit (const int reason) {
}


void OnTick(){
   int highestIndex = iHighest(_Symbol, Timeframe, MODE_HIGH, MinRangeBars, 1);
   int lowestIndex = iLowest (_Symbol, Timeframe, MODE_LOW, MinRangeBars, 1);
   double rangeHigh = iHigh (_Symbol, Timeframe, highestIndex);
   double rangeLow = iLow(_Symbol, Timeframe, lowestIndex);
   double rangeBarsSize = rangeHigh - rangeLow;
   double comparisonHigh = iHigh(_Symbol, Timeframe, iHighest(_Symbol, Timeframe, MODE_HIGH, ComparisonBars,1));
   double comparisonLow = iLow(_Symbol, Timeframe, iLowest (_Symbol, Timeframe, MODE_LOW, ComparisonBars, 1));
   double comparisonBarsSize = comparisonHigh-comparisonLow;
   
   
   if(setup.time1 <= 0){
      if (rangeBarsSize< comparisonBarsSize* MinRangeFactor){
         setup.time1 = iTime(_Symbol, Timeframe, 1);
         setup.timeX = iTime (_Symbol, Timeframe, MinRangeBars+1); setup.high = rangeHigh;
         setup.low = rangeLow;
         setup.drawRect();
      }
   }else{
   
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
      double riskPerLot = (setup.high- setup.low) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) *  SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double lots = riskPerLot / riskMoney;
      if(bid >=setup.high){
         if(PositionSelectByTicket(setup.posTicket)){
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
               lots = PositionGetDouble(POSITION_VOLUME) * MartingaleFactor;
               if(trade. PositionClose (setup.posTicket)){
                  setup.posTicket = 0;
                  setup.lostMoney += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
               }
            }
         }
      if(setup.posTicket <= 0){
         lots = NormalizeDouble(lots, 2);
         if(trade.Buy(lots)){
            setup.posTicket = trade.ResultOrder();
         }
      }
      }else if(bid <= setup.low){
         if(PositionSelectByTicket(setup.posTicket)){
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               lots = PositionGetDouble(POSITION_VOLUME) * MartingaleFactor;
               if(trade.PositionClose(setup.posTicket)){
                  setup.posTicket = 0;
                  setup.lostMoney += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
               }
            }
          }
          if(setup.posTicket <= 0){
            lots = NormalizeDouble(lots, 2);
            if(trade.Sell(lots)){
               setup.posTicket = trade.ResultOrder();
            }
            }
         }
         
         PositionSelectByTicket (setup.posTicket);
         if(setup.lostMoney + PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) > AccountInfoDouble(ACCOUNT_BALANCE) * TpPercent / 100){
            if(trade.PositionClose(setup.posTicket)){
               setup.time1 = 0;
               setup.posTicket = 0;
               setup.lostMoney = 0;
            }
         }
       }
}