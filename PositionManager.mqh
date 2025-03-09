//+------------------------------------------------------------------+
//|                           PositionManager.mqh                     |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"

#include <Trade/Trade.mqh>
#include "../Utils/Common.mqh"

//+------------------------------------------------------------------+
//| Class for position management functions                           |
//+------------------------------------------------------------------+
class CPositionManager {
private:
   // Trading object
   CTrade m_trade;
   
   // Position tracking
   PositionInfo m_positions[];
   int m_positionCount;
   int m_expertMagic;
   
   // Position management settings
   bool m_useTrailingStop;
   double m_trailingStartPips;
   double m_trailingDistancePips;
   ENUM_TRAILING_TYPE m_trailingType;
   double m_trailingATRMultiplier;
   double m_trailingPercentage;
   
   bool m_useBreakEven;
   double m_breakEvenTriggerPips;
   double m_breakEvenExtraPips;
   
   bool m_usePartialClose;
   double m_partialCloseTriggerPips;
   double m_partialClosePercent;
   
   bool m_useMultiLevelTP;
   double m_tpLevel1Percent;
   double m_tpLevel1Ratio;
   
   int m_maxHoldingTimeHours;
   
   // Symbol
   string m_symbol;
   
   // Helper functions
   double PipsToPrice(double pips);
   double PriceToPips(double price);
   bool IsOurPosition(ulong ticket);
   double GetPositionProfit(ulong ticket, bool inPips = false);
   datetime GetPositionOpenTime(ulong ticket);
   double GetPositionOpenPrice(ulong ticket);
   
public:
   // Constructor
   CPositionManager(
      string symbol,
      int expertMagic,
      bool useTrailingStop = true,
      double trailingStartPips = 15.0,
      double trailingDistancePips = 10.0,
      ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_FIXED,
      double trailingATRMultiplier = 0.8,
      double trailingPercentage = 80.0,
      bool useBreakEven = true,
      double breakEvenTriggerPips = 10.0,
      double breakEvenExtraPips = 1.0,
      bool usePartialClose = true,
      double partialCloseTriggerPips = 12.0,
      double partialClosePercent = 50.0,
      bool useMultiLevelTP = false,
      double tpLevel1Percent = 30.0,
      double tpLevel1Ratio = 1.0,
      int maxHoldingTimeHours = 48
   );
   
   // Destructor
   ~CPositionManager() {};
   
   // Initialize with settings
   void Initialize(int expertMagic);
   
   // Set position management parameters
   void SetTrailingStopParameters(bool useTrailing, double startPips, double distancePips, ENUM_TRAILING_TYPE type);
   void SetBreakEvenParameters(bool useBreakEven, double triggerPips, double extraPips);
   void SetPartialCloseParameters(bool usePartialClose, double triggerPips, double percentage);
   void SetMultiTPParameters(bool useMultiLevelTP, double level1Percent, double level1Ratio);
   void SetMaxHoldingTime(int hours);
   
   // Update all positions (call this from OnTick)
   void UpdatePositions();
   
   // Manage a specific position
   bool ManagePosition(ulong ticket);
   
   // Apply trailing stop to a position
   bool ApplyTrailingStop(ulong ticket, double atr = 0.0);
   
   // Set break-even stop
   bool SetBreakEven(ulong ticket);
   
   // Partially close a position
   bool PartialClosePosition(ulong ticket, double percentage);
   
   // Get position count
   int GetPositionCount() { return m_positionCount; }
   
   // Get total profit (all positions)
   double GetTotalProfit(bool inPips = false);
   
   // Close position by ticket
   bool ClosePosition(ulong ticket);
   
   // Close all positions
   bool CloseAllPositions();
   
   // Close all profitable positions
   bool CloseAllProfitablePositions(double minProfit = 0.0);
   
   // Close positions open too long
   bool CloseOldPositions();
   
   // Get the status of a position (in profit, in loss, etc.)
   string GetPositionStatus(ulong ticket);
   
   // Set the magic number
   void SetMagicNumber(int magic) { m_expertMagic = magic; m_trade.SetExpertMagicNumber(magic); }
   
   // Open a new position
   bool OpenPosition(
      int orderType,              // 0 = buy, 1 = sell
      double volume,
      double stopLoss,
      double takeProfit,
      string comment = "",
      ENUM_MARKET_STRUCTURE marketStructure = MARKET_UNKNOWN,
      double hurstValue = 0.5
   );
   
   // Modify an existing position
   bool ModifyPosition(ulong ticket, double stopLoss, double takeProfit);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CPositionManager::CPositionManager(
   string symbol,
   int expertMagic,
   bool useTrailingStop,
   double trailingStartPips,
   double trailingDistancePips,
   ENUM_TRAILING_TYPE trailingType,
   double trailingATRMultiplier,
   double trailingPercentage,
   bool useBreakEven,
   double breakEvenTriggerPips,
   double breakEvenExtraPips,
   bool usePartialClose,
   double partialCloseTriggerPips,
   double partialClosePercent,
   bool useMultiLevelTP,
   double tpLevel1Percent,
   double tpLevel1Ratio,
   int maxHoldingTimeHours
) : m_symbol(symbol),
    m_expertMagic(expertMagic),
    m_useTrailingStop(useTrailingStop),
    m_trailingStartPips(trailingStartPips),
    m_trailingDistancePips(trailingDistancePips),
    m_trailingType(trailingType),
    m_trailingATRMultiplier(trailingATRMultiplier),
    m_trailingPercentage(trailingPercentage),
    m_useBreakEven(useBreakEven),
    m_breakEvenTriggerPips(breakEvenTriggerPips),
    m_breakEvenExtraPips(breakEvenExtraPips),
    m_usePartialClose(usePartialClose),
    m_partialCloseTriggerPips(partialCloseTriggerPips),
    m_partialClosePercent(partialClosePercent),
    m_useMultiLevelTP(useMultiLevelTP),
    m_tpLevel1Percent(tpLevel1Percent),
    m_tpLevel1Ratio(tpLevel1Ratio),
    m_maxHoldingTimeHours(maxHoldingTimeHours)
{
   // Set expert magic
   m_trade.SetExpertMagicNumber(expertMagic);
   
   // Initialize position tracking
   m_positionCount = 0;
   ArrayResize(m_positions, 0);
}

//+------------------------------------------------------------------+
//| Initialize position manager                                       |
//+------------------------------------------------------------------+
void CPositionManager::Initialize(int expertMagic) {
   m_expertMagic = expertMagic;
   m_trade.SetExpertMagicNumber(expertMagic);
   
   // Reset position tracking
   m_positionCount = 0;
   ArrayResize(m_positions, 0);
}

//+------------------------------------------------------------------+
//| Set trailing stop parameters                                       |
//+------------------------------------------------------------------+
void CPositionManager::SetTrailingStopParameters(
   bool useTrailing,
   double startPips,
   double distancePips,
   ENUM_TRAILING_TYPE type
) {
   m_useTrailingStop = useTrailing;
   m_trailingStartPips = startPips;
   m_trailingDistancePips = distancePips;
   m_trailingType = type;
}

//+------------------------------------------------------------------+
//| Set break-even parameters                                         |
//+------------------------------------------------------------------+
void CPositionManager::SetBreakEvenParameters(
   bool useBreakEven,
   double triggerPips,
   double extraPips
) {
   m_useBreakEven = useBreakEven;
   m_breakEvenTriggerPips = triggerPips;
   m_breakEvenExtraPips = extraPips;
}

//+------------------------------------------------------------------+
//| Set partial close parameters                                      |
//+------------------------------------------------------------------+
void CPositionManager::SetPartialCloseParameters(
   bool usePartialClose,
   double triggerPips,
   double percentage
) {
   m_usePartialClose = usePartialClose;
   m_partialCloseTriggerPips = triggerPips;
   m_partialClosePercent = percentage;
}

//+------------------------------------------------------------------+
//| Set multi-level TP parameters                                     |
//+------------------------------------------------------------------+
void CPositionManager::SetMultiTPParameters(
   bool useMultiLevelTP,
   double level1Percent,
   double level1Ratio
) {
   m_useMultiLevelTP = useMultiLevelTP;
   m_tpLevel1Percent = level1Percent;
   m_tpLevel1Ratio = level1Ratio;
}

//+------------------------------------------------------------------+
//| Set max holding time                                              |
//+------------------------------------------------------------------+
void CPositionManager::SetMaxHoldingTime(int hours) {
   m_maxHoldingTimeHours = hours;
}

//+------------------------------------------------------------------+
//| Update all positions (call from OnTick)                           |
//+------------------------------------------------------------------+
void CPositionManager::UpdatePositions() {
   // Count positions with our magic number
   m_positionCount = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsOurPosition(ticket)) {
         m_positionCount++;
      }
   }
   
   // Resize array to match position count
   ArrayResize(m_positions, m_positionCount);
   
   // Fill position info array
   int index = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsOurPosition(ticket)) {
         ManagePosition(ticket);
         
         // Update our tracking array
         if(index < m_positionCount) {
            if(PositionSelectByTicket(ticket)) {
               m_positions[index].ticket = ticket;
               m_positions[index].openTime = PositionGetInteger(POSITION_TIME);
               m_positions[index].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               m_positions[index].lotsTotal = PositionGetDouble(POSITION_VOLUME);
               m_positions[index].lotsCurrent = PositionGetDouble(POSITION_VOLUME); // Update if partially closed
               m_positions[index].stopLoss = PositionGetDouble(POSITION_SL);
               m_positions[index].takeProfit = PositionGetDouble(POSITION_TP);
               m_positions[index].positionType = (int)PositionGetInteger(POSITION_TYPE);
               
               // Other tracking fields would be set when opening the position
               
               index++;
            }
         }
      }
   }
   
   // Close old positions if max holding time is set
   if(m_maxHoldingTimeHours > 0) {
      CloseOldPositions();
   }
}

//+------------------------------------------------------------------+
//| Manage a specific position                                        |
//+------------------------------------------------------------------+
bool CPositionManager::ManagePosition(ulong ticket) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return false;
   
   double posProfit = GetPositionProfit(ticket, true); // Profit in pips
   
   // Apply break-even if enabled and condition met
   if(m_useBreakEven && posProfit >= m_breakEvenTriggerPips) {
      SetBreakEven(ticket);
   }
   
   // Apply partial close if enabled and condition met
   if(m_usePartialClose && posProfit >= m_partialCloseTriggerPips) {
      // Check if the position has already been partially closed
      bool alreadyPartiallyClosed = false;
      
      for(int i = 0; i < m_positionCount; i++) {
         if(m_positions[i].ticket == ticket && m_positions[i].isPartialClosed) {
            alreadyPartiallyClosed = true;
            break;
         }
      }
      
      if(!alreadyPartiallyClosed) {
         PartialClosePosition(ticket, m_partialClosePercent);
         
         // Update our tracking
         for(int i = 0; i < m_positionCount; i++) {
            if(m_positions[i].ticket == ticket) {
               m_positions[i].isPartialClosed = true;
               break;
            }
         }
      }
   }
   
   // Apply trailing stop if enabled and condition met
   if(m_useTrailingStop && posProfit >= m_trailingStartPips) {
      ApplyTrailingStop(ticket);
      
      // Update our tracking
      for(int i = 0; i < m_positionCount; i++) {
         if(m_positions[i].ticket == ticket) {
            m_positions[i].isTrailingActive = true;
            break;
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Apply trailing stop to a position                                 |
//+------------------------------------------------------------------+
bool CPositionManager::ApplyTrailingStop(ulong ticket, double atr = 0.0) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return false;
   
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double positionType = PositionGetInteger(POSITION_TYPE); // 0=buy, 1=sell
   
   double newSL = 0;
   
   // Calculate new stop loss based on trailing type
   switch(m_trailingType) {
      case TRAILING_TYPE_FIXED:
         // Fixed distance trailing stop
         if(positionType == 0) { // Buy position
            newSL = currentPrice - PipsToPrice(m_trailingDistancePips);
            if(newSL > currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         else { // Sell position
            newSL = currentPrice + PipsToPrice(m_trailingDistancePips);
            if(newSL < currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         break;
         
      case TRAILING_TYPE_ATR:
         // ATR-based trailing stop
         if(atr <= 0) atr = 1.0; // Default if ATR not provided
         
         if(positionType == 0) { // Buy position
            newSL = currentPrice - (atr * m_trailingATRMultiplier);
            if(newSL > currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         else { // Sell position
            newSL = currentPrice + (atr * m_trailingATRMultiplier);
            if(newSL < currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         break;
         
      case TRAILING_TYPE_PERCENTAGE:
         // Percentage of profit trailing
         double profitPoints = 0;
         
         if(positionType == 0) { // Buy position
            profitPoints = currentPrice - openPrice;
            newSL = openPrice + (profitPoints * (m_trailingPercentage / 100.0));
            if(newSL > currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         else { // Sell position
            profitPoints = openPrice - currentPrice;
            newSL = openPrice - (profitPoints * (m_trailingPercentage / 100.0));
            if(newSL < currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         break;
         
      // Additional trailing types can be implemented here
      
      default:
         // Default to fixed trailing stop
         if(positionType == 0) { // Buy position
            newSL = currentPrice - PipsToPrice(m_trailingDistancePips);
            if(newSL > currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         else { // Sell position
            newSL = currentPrice + PipsToPrice(m_trailingDistancePips);
            if(newSL < currentSL || currentSL == 0)
               m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
         break;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Set break-even stop                                               |
//+------------------------------------------------------------------+
bool CPositionManager::SetBreakEven(ulong ticket) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return false;
   
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double positionType = PositionGetInteger(POSITION_TYPE); // 0=buy, 1=sell
   
   double newSL = 0;
   
   // Calculate break-even level plus extra pips
   if(positionType == 0) { // Buy position
      newSL = openPrice + PipsToPrice(m_breakEvenExtraPips);
      if(newSL > currentSL || currentSL == 0)
         m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
   }
   else { // Sell position
      newSL = openPrice - PipsToPrice(m_breakEvenExtraPips);
      if(newSL < currentSL || currentSL == 0)
         m_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Partially close a position                                        |
//+------------------------------------------------------------------+
bool CPositionManager::PartialClosePosition(ulong ticket, double percentage) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return false;
   
   double volume = PositionGetDouble(POSITION_VOLUME);
   double volumeToClose = volume * (percentage / 100.0);
   double minLot = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_VOLUME_MIN);
   
   // Ensure volumeToClose is not less than minimum lot size
   if(volumeToClose < minLot) {
      // Cannot close partially (volume too small)
      return false;
   }
   
   // Close partial position
   return m_trade.PositionClosePartial(ticket, volumeToClose);
}

//+------------------------------------------------------------------+
//| Get total profit (all positions)                                  |
//+------------------------------------------------------------------+
double CPositionManager::GetTotalProfit(bool inPips = false) {
   double totalProfit = 0;
   
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsOurPosition(ticket)) {
         if(inPips)
            totalProfit += GetPositionProfit(ticket, true);
         else
            totalProfit += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   return totalProfit;
}

//+------------------------------------------------------------------+
//| Close position by ticket                                          |
//+------------------------------------------------------------------+
bool CPositionManager::ClosePosition(ulong ticket) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return false;
   
   return m_trade.PositionClose(ticket);
}

//+------------------------------------------------------------------+
//| Close all positions                                               |
//+------------------------------------------------------------------+
bool CPositionManager::CloseAllPositions() {
   bool success = true;
   
   // Copy tickets to array first to avoid issues with changing position count
   ulong tickets[];
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsOurPosition(ticket)) {
         count++;
         ArrayResize(tickets, count);
         tickets[count-1] = ticket;
      }
   }
   
   // Close positions using copied tickets
   for(int i = 0; i < count; i++) {
      if(!m_trade.PositionClose(tickets[i]))
         success = false;
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Close all profitable positions                                    |
//+------------------------------------------------------------------+
bool CPositionManager::CloseAllProfitablePositions(double minProfit = 0.0) {
   bool success = true;
   
   // Copy tickets to array first to avoid issues with changing position count
   ulong tickets[];
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsOurPosition(ticket)) {
         double profit = PositionGetDouble(POSITION_PROFIT);
         if(profit >= minProfit) {
            count++;
            ArrayResize(tickets, count);
            tickets[count-1] = ticket;
         }
      }
   }
   
   // Close positions using copied tickets
   for(int i = 0; i < count; i++) {
      if(!m_trade.PositionClose(tickets[i]))
         success = false;
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Close positions open too long                                     |
//+------------------------------------------------------------------+
bool CPositionManager::CloseOldPositions() {
   if(m_maxHoldingTimeHours <= 0)
      return true; // Feature disabled
   
   bool success = true;
   datetime currentTime = TimeCurrent();
   int secondsLimit = m_maxHoldingTimeHours * 3600;
   
   // Copy tickets to array first to avoid issues with changing position count
   ulong tickets[];
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsOurPosition(ticket)) {
         datetime openTime = PositionGetInteger(POSITION_TIME);
         if((currentTime - openTime) >= secondsLimit) {
            count++;
            ArrayResize(tickets, count);
            tickets[count-1] = ticket;
         }
      }
   }
   
   // Close positions using copied tickets
   for(int i = 0; i < count; i++) {
      if(!m_trade.PositionClose(tickets[i]))
         success = false;
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Get the status of a position                                     |
//+------------------------------------------------------------------+
string CPositionManager::GetPositionStatus(ulong ticket) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return "Unknown";
   
   double profit = PositionGetDouble(POSITION_PROFIT);
   double profitPips = GetPositionProfit(ticket, true);
   
   string status = "";
   
   // Check if trailing is active
   bool trailingActive = false;
   for(int i = 0; i < m_positionCount; i++) {
      if(m_positions[i].ticket == ticket && m_positions[i].isTrailingActive) {
         trailingActive = true;
         break;
      }
   }
   
   // Check if partially closed
   bool partialClosed = false;
   for(int i = 0; i < m_positionCount; i++) {
      if(m_positions[i].ticket == ticket && m_positions[i].isPartialClosed) {
         partialClosed = true;
         break;
      }
   }
   
   // Determine status
   if(profit > 0) {
      status = "Profit " + DoubleToString(profitPips, 1) + " pips";
      if(trailingActive)
         status += " (Trailing)";
      if(partialClosed)
         status += " (Partial)";
   }
   else if(profit < 0) {
      status = "Loss " + DoubleToString(MathAbs(profitPips), 1) + " pips";
   }
   else {
      status = "Breakeven";
   }
   
   return status;
}

//+------------------------------------------------------------------+
//| Open a new position                                               |
//+------------------------------------------------------------------+
bool CPositionManager::OpenPosition(
   int orderType,              // 0 = buy, 1 = sell
   double volume,
   double stopLoss,
   double takeProfit,
   string comment = "",
   ENUM_MARKET_STRUCTURE marketStructure = MARKET_UNKNOWN,
   double hurstValue = 0.5
) {
   if(volume <= 0)
      return false;
   
   ENUM_ORDER_TYPE type = (orderType == 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = (orderType == 0) ? SymbolInfoDouble(m_symbol, SYMBOL_ASK) : SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   // Send the order
   bool result = m_trade.PositionOpen(m_symbol, type, volume, price, stopLoss, takeProfit, comment);
   
   // If successful, store additional info
   if(result) {
      ulong ticket = m_trade.ResultOrder();
      
      // Update position info with market structure and Hurst value
      for(int i = 0; i < m_positionCount; i++) {
         if(m_positions[i].ticket == ticket) {
            m_positions[i].marketStructureAtOpen = marketStructure;
            m_positions[i].hurstAtOpen = hurstValue;
            break;
         }
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Modify an existing position                                       |
//+------------------------------------------------------------------+
bool CPositionManager::ModifyPosition(ulong ticket, double stopLoss, double takeProfit) {
   if(!PositionSelectByTicket(ticket) || !IsOurPosition(ticket))
      return false;
   
   return m_trade.PositionModify(ticket, stopLoss, takeProfit);
}

//+------------------------------------------------------------------+
//| Helper: Convert pips to price                                     |
//+------------------------------------------------------------------+
double CPositionManager::PipsToPrice(double pips) {
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   
   double pipValue = point;
   if(digits == 3 || digits == 5)
      pipValue = point * 10;
   
   return pips * pipValue;
}

//+------------------------------------------------------------------+
//| Helper: Convert price to pips                                     |
//+------------------------------------------------------------------+
double CPositionManager::PriceToPips(double price) {
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   
   double pipValue = point;
   if(digits == 3 || digits == 5)
      pipValue = point * 10;
   
   return price / pipValue;
}

//+------------------------------------------------------------------+
//| Helper: Check if position belongs to our EA                       |
//+------------------------------------------------------------------+
bool CPositionManager::IsOurPosition(ulong ticket) {
   if(!PositionSelectByTicket(ticket))
      return false;
   
   return PositionGetInteger(POSITION_MAGIC) == m_expertMagic;
}

//+------------------------------------------------------------------+
//| Helper: Get position profit in currency or pips                   |
//+------------------------------------------------------------------+
double CPositionManager::GetPositionProfit(ulong ticket, bool inPips = false) {
   if(!PositionSelectByTicket(ticket))
      return 0;
   
   double profit = PositionGetDouble(POSITION_PROFIT);
   
   if(inPips) {
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      int positionType = (int)PositionGetInteger(POSITION_TYPE); // 0=buy, 1=sell
      
      double priceDiff = (positionType == 0) ? currentPrice - openPrice : openPrice - currentPrice;
      return PriceToPips(priceDiff);
   }
   
   return profit;
}

//+------------------------------------------------------------------+
//| Helper: Get position open time                                    |
//+------------------------------------------------------------------+
datetime CPositionManager::GetPositionOpenTime(ulong ticket) {
   if(!PositionSelectByTicket(ticket))
      return 0;
   
   return (datetime)PositionGetInteger(POSITION_TIME);
}

//+------------------------------------------------------------------+
//| Helper: Get position open price                                   |
//+------------------------------------------------------------------+
double CPositionManager::GetPositionOpenPrice(ulong ticket) {
   if(!PositionSelectByTicket(ticket))
      return 0;
   
   return PositionGetDouble(POSITION_PRICE_OPEN);
} 