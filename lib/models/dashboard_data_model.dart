import 'dart:convert';

List<DashboardDataModel> dashboardDataModelFromJson(String str) =>
    List<DashboardDataModel>.from(
        json.decode(str).map((x) => DashboardDataModel.fromJson(x)));

String dashboardDataModelToJson(List<DashboardDataModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DashboardDataModel {
  double? adultEducation;
  double? annualSales1;
  String? avTicketTrustGrade;
  double? childernEducation;
  double? dailyCustomerCount;
  double? dailyPurchase;
  double? dailySales;
  String? eduGrade;
  String? empGrade;
  String? foodCostTrustGrade;
  double? fulltimeEmployee;
  double? grossMargin;
  double? grossMarginChk;
  String? hrGrade;
  double? householdCost;
  String? householdCostHouseholdCostWoRtEdCode;
  String? householdCostHouseholdFoodCostCode;
  String? householdCostHouseholdOtherCostOmtCode;
  String? householdCostHouseholdUtilityCostCode;
  String? householdCostMonthlySalesCode;
  String? householdCostTakeHomeIncomeWoEmRtCode;
  String? householdCostTrustGrade;
  double? householdCostWoRtEd;
  double? householdEducationCost;
  double? householdFoodCost;
  double? householdMedicalCost;
  double? householdOtherCost;
  double? householdOtherCostOmt;
  double? householdRentalCost;
  double? householdSavings;
  double? householdSize;
  double? householdTransportCost;
  double? householdUtilityCost;
  double? householdCheck;
  double? householdCheckRange;
  String? incomeHouseholdCostWoRtEdCode;
  String? incomeMonthlyGrossProfitCode;
  String? incomeMonthlySalesCode;
  String? incomeMonthlyOperatingCostsWoEmRtCode;
  String? incomeOffSalesCode;
  String? incomePeakSalesCode;
  String? incomeTrustGrade;
  double? inventoryShop;
  double? inventoryWarehouse;
  double? inventoryBySales;
  double? inventoryBySalesChk;
  double? irregularPurchase;
  double? monthlyGrossMargin;
  double? monthlyGrossProfit;
  double? monthlyPurchase;
  double? monthlySales;
  double? monthlyOperatingCosts;
  double? monthlyOperatingCostsWoEmRt;
  double? offDuration;
  double? offSales;
  double? operatingCheck;
  double? operatingCheckRange;
  String? operatingCostMonthlySalesCode;
  String? operatingCostMonthlyOperatingCostsWoEmRtCode;
  String? operatingCostShopElectricCostCode;
  String? operatingCostShopTransportCostCode;
  String? operatingCostTakeHomeIncomeWoEmRtCode;
  String? operatingCostTrustGrade;
  double? parttimeEmployee;
  double? peakDuration;
  double? peakSales;
  String? srGrade;
  String? salesPrequalifierGrade;
  double? salesPrequalifierScore;
  double? shopElectricCost;
  double? shopEmployeeCost;
  double? shopOtherCost;
  double? shopRentalCost;
  double? shopTransportCost;
  double? takeHomeIncome;
  double? takeHomeIncomeWoEmRt;
  double? totalInventory;
  double? totalPurchase;
  double? trustScore;
  double? weeklyPurchase;
  double? weeklySales;
  double? monthlyByAnnualSales;
  double? monthlyByAnnualSalesChk;
  double? monthlyByDailySales;
  double? monthlyByDailySalesChk;
  double? monthlyByWeeklySales;
  double? monthlyByWeeklySalesChk;

  DashboardDataModel({
    this.adultEducation,
    this.annualSales1,
    this.avTicketTrustGrade,
    this.childernEducation,
    this.dailyCustomerCount,
    this.dailyPurchase,
    this.dailySales,
    this.eduGrade,
    this.empGrade,
    this.foodCostTrustGrade,
    this.fulltimeEmployee,
    this.grossMargin,
    this.grossMarginChk,
    this.hrGrade,
    this.householdCost,
    this.householdCostHouseholdCostWoRtEdCode,
    this.householdCostHouseholdFoodCostCode,
    this.householdCostHouseholdOtherCostOmtCode,
    this.householdCostHouseholdUtilityCostCode,
    this.householdCostMonthlySalesCode,
    this.householdCostTakeHomeIncomeWoEmRtCode,
    this.householdCostTrustGrade,
    this.householdCostWoRtEd,
    this.householdEducationCost,
    this.householdFoodCost,
    this.householdMedicalCost,
    this.householdOtherCost,
    this.householdOtherCostOmt,
    this.householdRentalCost,
    this.householdSavings,
    this.householdSize,
    this.householdTransportCost,
    this.householdUtilityCost,
    this.householdCheck,
    this.householdCheckRange,
    this.incomeHouseholdCostWoRtEdCode,
    this.incomeMonthlyGrossProfitCode,
    this.incomeMonthlySalesCode,
    this.incomeMonthlyOperatingCostsWoEmRtCode,
    this.incomeOffSalesCode,
    this.incomePeakSalesCode,
    this.incomeTrustGrade,
    this.inventoryShop,
    this.inventoryWarehouse,
    this.inventoryBySales,
    this.inventoryBySalesChk,
    this.irregularPurchase,
    this.monthlyGrossMargin,
    this.monthlyGrossProfit,
    this.monthlyPurchase,
    this.monthlySales,
    this.monthlyOperatingCosts,
    this.monthlyOperatingCostsWoEmRt,
    this.offDuration,
    this.offSales,
    this.operatingCheck,
    this.operatingCheckRange,
    this.operatingCostMonthlySalesCode,
    this.operatingCostMonthlyOperatingCostsWoEmRtCode,
    this.operatingCostShopElectricCostCode,
    this.operatingCostShopTransportCostCode,
    this.operatingCostTakeHomeIncomeWoEmRtCode,
    this.operatingCostTrustGrade,
    this.parttimeEmployee,
    this.peakDuration,
    this.peakSales,
    this.srGrade,
    this.salesPrequalifierGrade,
    this.salesPrequalifierScore,
    this.shopElectricCost,
    this.shopEmployeeCost,
    this.shopOtherCost,
    this.shopRentalCost,
    this.shopTransportCost,
    this.takeHomeIncome,
    this.takeHomeIncomeWoEmRt,
    this.totalInventory,
    this.totalPurchase,
    this.trustScore,
    this.weeklyPurchase,
    this.weeklySales,
    this.monthlyByAnnualSales,
    this.monthlyByAnnualSalesChk,
    this.monthlyByDailySales,
    this.monthlyByDailySalesChk,
    this.monthlyByWeeklySales,
    this.monthlyByWeeklySalesChk,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) =>
      DashboardDataModel(
        adultEducation: json["Adult_Education"]?.toDouble(),
        annualSales1: json["Annual_Sales_1"]?.toDouble(),
        avTicketTrustGrade: json["Av_Ticket_Trust_Grade"],
        childernEducation: json["Childern_Education"]?.toDouble(),
        dailyCustomerCount: json["Daily_Customer_Count"]?.toDouble(),
        dailyPurchase: json["Daily_Purchase"]?.toDouble(),
        dailySales: json["Daily_Sales"]?.toDouble(),
        eduGrade: json["Edu_Grade"],
        empGrade: json["Emp_Grade"],
        foodCostTrustGrade: json["Food_Cost_Trust_Grade"],
        fulltimeEmployee: json["Fulltime_Employee"]?.toDouble(),
        grossMargin: json["Gross_Margin"]?.toDouble(),
        grossMarginChk: json["Gross_Margin_chk"]?.toDouble(),
        hrGrade: json["HR_Grade"],
        householdCost: json["Household_Cost"]?.toDouble(),
        householdCostHouseholdCostWoRtEdCode: json["Household_Cost_Household_Cost_wo_rt_ed_Code"],
        householdCostHouseholdFoodCostCode: json["Household_Cost_Household_Food_Cost_Code"],
        householdCostHouseholdOtherCostOmtCode: json["Household_Cost_Household_Other_Cost_OMT_Code"],
        householdCostHouseholdUtilityCostCode: json["Household_Cost_Household_Utility_Cost_Code"],
        householdCostMonthlySalesCode: json["Household_Cost_Monthly_Sales_Code"],
        householdCostTakeHomeIncomeWoEmRtCode: json["Household_Cost_Take_Home_Income_wo_em_rt_Code"],
        householdCostTrustGrade: json["Household_Cost_Trust_Grade"],
        householdCostWoRtEd: json["Household_Cost_wo_rt_ed"]?.toDouble(),
        householdEducationCost: json["Household_Education_Cost"]?.toDouble(),
        householdFoodCost: json["Household_Food_Cost"]?.toDouble(),
        householdMedicalCost: json["Household_Medical_Cost"]?.toDouble(),
        householdOtherCost: json["Household_Other_Cost"]?.toDouble(),
        householdOtherCostOmt: json["Household_Other_Cost_OMT"]?.toDouble(),
        householdRentalCost: json["Household_Rental_Cost"]?.toDouble(),
        householdSavings: json["Household_Savings"]?.toDouble(),
        householdSize: json["Household_Size"]?.toDouble(),
        householdTransportCost: json["Household_Transport_Cost"]?.toDouble(),
        householdUtilityCost: json["Household_Utility_Cost"]?.toDouble(),
        householdCheck: json["Household_Check"]?.toDouble(),
        householdCheckRange: json["Household_Check_Range"]?.toDouble(),
        incomeHouseholdCostWoRtEdCode: json["Income_Household_Cost_wo_rt_ed_Code"],
        incomeMonthlyGrossProfitCode: json["Income_Monthly_Gross_Profit_Code"],
        incomeMonthlySalesCode: json["Income_Monthly_Sales_Code"],
        incomeMonthlyOperatingCostsWoEmRtCode: json["Income_Monthly_Operating_Costs_wo_em_rt_Code"],
        incomeOffSalesCode: json["Income_Off_Sales_Code"],
        incomePeakSalesCode: json["Income_Peak_Sales_Code"],
        incomeTrustGrade: json["Income_Trust_Grade"],
        inventoryShop: json["Inventory_Shop"]?.toDouble(),
        inventoryWarehouse: json["Inventory_Warehouse"]?.toDouble(),
        inventoryBySales: json["Inventory_By_Sales"]?.toDouble(),
        inventoryBySalesChk: json["Inventory_By_Sales_chk"]?.toDouble(),
        irregularPurchase: json["Irregular_Purchase"]?.toDouble(),
        monthlyGrossMargin: json["Monthly_Gross_Margin"]?.toDouble(),
        monthlyGrossProfit: json["Monthly_Gross_Profit"]?.toDouble(),
        monthlyPurchase: json["Monthly_Purchase"]?.toDouble(),
        monthlySales: json["Monthly_Sales"]?.toDouble(),
        monthlyOperatingCosts: json["Monthly_Operating_Costs"]?.toDouble(),
        monthlyOperatingCostsWoEmRt: json["Monthly_Operating_Costs_wo_em_rt"]
            ?.toDouble(),
        offDuration: json["Off_Duration"]?.toDouble(),
        offSales: json["Off_Sales"]?.toDouble(),
        operatingCheck: json["Operating_Check"]?.toDouble(),
        operatingCheckRange: json["Operating_Check_Range"]?.toDouble(),
        operatingCostMonthlySalesCode: json["Operating_Cost_Monthly_Sales_Code"],
        operatingCostMonthlyOperatingCostsWoEmRtCode: json["Operating_Cost_Monthly_Operating_Costs_wo_em_rt_Code"],
        operatingCostShopElectricCostCode: json["Operating_Cost_Shop_Electric_Cost_Code"],
        operatingCostShopTransportCostCode: json["Operating_Cost_Shop_Transport_Cost_Code"],
        operatingCostTakeHomeIncomeWoEmRtCode: json["Operating_Cost_Take_Home_Income_wo_em_rt_Code"],
        operatingCostTrustGrade: json["Operating_Cost_Trust_Grade"],
        parttimeEmployee: json["Parttime_Employee"]?.toDouble(),
        peakDuration: json["Peak_Duration"]?.toDouble(),
        peakSales: json["Peak_Sales"]?.toDouble(),
        srGrade: json["SR_Grade"],
        salesPrequalifierGrade: json["Sales_Prequalifier_Grade"],
        salesPrequalifierScore: json["Sales_Prequalifier_Score"]?.toDouble(),
        shopElectricCost: json["Shop_Electric_Cost"]?.toDouble(),
        shopEmployeeCost: json["Shop_Employee_Cost"]?.toDouble(),
        shopOtherCost: json["Shop_Other_Cost"]?.toDouble(),
        shopRentalCost: json["Shop_Rental_Cost"]?.toDouble(),
        shopTransportCost: json["Shop_Transport_Cost"]?.toDouble(),
        takeHomeIncome: json["Take_Home_Income"]?.toDouble(),
        takeHomeIncomeWoEmRt: json["Take_Home_Income_wo_em_rt"]?.toDouble(),
        totalInventory: json["Total_Inventory"]?.toDouble(),
        totalPurchase: json["Total_Purchase"]?.toDouble(),
        trustScore: json["Trust_Score"]?.toDouble(),
        weeklyPurchase: json["Weekly_Purchase"]?.toDouble(),
        weeklySales: json["Weekly_Sales"]?.toDouble(),
        monthlyByAnnualSales: json["Monthly_by_Annual_Sales"]?.toDouble(),
        monthlyByAnnualSalesChk: json["Monthly_by_Annual_Sales_chk"]
            ?.toDouble(),
        monthlyByDailySales: json["Monthly_by_Daily_Sales"]?.toDouble(),
        monthlyByDailySalesChk: json["Monthly_by_Daily_Sales_chk"]?.toDouble(),
        monthlyByWeeklySales: json["Monthly_by_Weekly_Sales"]?.toDouble(),
        monthlyByWeeklySalesChk: json["Monthly_by_Weekly_Sales_chk"]
            ?.toDouble(),
      );

  Map<String, dynamic> toJson() =>
      {
        "Adult_Education": adultEducation,
        "Annual_Sales_1": annualSales1,
        "Av_Ticket_Trust_Grade": avTicketTrustGrade,
        "Childern_Education": childernEducation,
        "Daily_Customer_Count": dailyCustomerCount,
        "Daily_Purchase": dailyPurchase,
        "Daily_Sales": dailySales,
        "Edu_Grade": eduGrade,
        "Emp_Grade": empGrade,
        "Food_Cost_Trust_Grade": foodCostTrustGrade,
        "Fulltime_Employee": fulltimeEmployee,
        "Gross_Margin": grossMargin,
        "Gross_Margin_chk": grossMarginChk,
        "HR_Grade": hrGrade,
        "Household_Cost": householdCost,
        "Household_Cost_Household_Cost_wo_rt_ed_Code": householdCostHouseholdCostWoRtEdCode,
        "Household_Cost_Household_Food_Cost_Code": householdCostHouseholdFoodCostCode,
        "Household_Cost_Household_Other_Cost_OMT_Code": householdCostHouseholdOtherCostOmtCode,
        "Household_Cost_Household_Utility_Cost_Code": householdCostHouseholdUtilityCostCode,
        "Household_Cost_Monthly_Sales_Code": householdCostMonthlySalesCode,
        "Household_Cost_Take_Home_Income_wo_em_rt_Code": householdCostTakeHomeIncomeWoEmRtCode,
        "Household_Cost_Trust_Grade": householdCostTrustGrade,
        "Household_Cost_wo_rt_ed": householdCostWoRtEd,
        "Household_Education_Cost": householdEducationCost,
        "Household_Food_Cost": householdFoodCost,
        "Household_Medical_Cost": householdMedicalCost,
        "Household_Other_Cost": householdOtherCost,
        "Household_Other_Cost_OMT": householdOtherCostOmt,
        "Household_Rental_Cost": householdRentalCost,
        "Household_Savings": householdSavings,
        "Household_Size": householdSize,
        "Household_Transport_Cost": householdTransportCost,
        "Household_Utility_Cost": householdUtilityCost,
        "Household_Check": householdCheck,
        "Household_Check_Range": householdCheckRange,
        "Income_Household_Cost_wo_rt_ed_Code": incomeHouseholdCostWoRtEdCode,
        "Income_Monthly_Gross_Profit_Code": incomeMonthlyGrossProfitCode,
        "Income_Monthly_Sales_Code": incomeMonthlySalesCode,
        "Income_Monthly_Operating_Costs_wo_em_rt_Code": incomeMonthlyOperatingCostsWoEmRtCode,
        "Income_Off_Sales_Code": incomeOffSalesCode,
        "Income_Peak_Sales_Code": incomePeakSalesCode,
        "Income_Trust_Grade": incomeTrustGrade,
        "Inventory_Shop": inventoryShop,
        "Inventory_Warehouse": inventoryWarehouse,
        "Inventory_By_Sales": inventoryBySales,
        "Inventory_By_Sales_chk": inventoryBySalesChk,
        "Irregular_Purchase": irregularPurchase,
        "Monthly_Gross_Margin": monthlyGrossMargin,
        "Monthly_Gross_Profit": monthlyGrossProfit,
        "Monthly_Purchase": monthlyPurchase,
        "Monthly_Sales": monthlySales,
        "Monthly_Operating_Costs": monthlyOperatingCosts,
        "Monthly_Operating_Costs_wo_em_rt": monthlyOperatingCostsWoEmRt,
        "Off_Duration": offDuration,
        "Off_Sales": offSales,
        "Operating_Check": operatingCheck,
        "Operating_Check_Range": operatingCheckRange,
        "Operating_Cost_Monthly_Sales_Code": operatingCostMonthlySalesCode,
        "Operating_Cost_Monthly_Operating_Costs_wo_em_rt_Code": operatingCostMonthlyOperatingCostsWoEmRtCode,
        "Operating_Cost_Shop_Electric_Cost_Code": operatingCostShopElectricCostCode,
        "Operating_Cost_Shop_Transport_Cost_Code": operatingCostShopTransportCostCode,
        "Operating_Cost_Take_Home_Income_wo_em_rt_Code": operatingCostTakeHomeIncomeWoEmRtCode,
        "Operating_Cost_Trust_Grade": operatingCostTrustGrade,
        "Parttime_Employee": parttimeEmployee,
        "Peak_Duration": peakDuration,
        "Peak_Sales": peakSales,
        "SR_Grade": srGrade,
        "Sales_Prequalifier_Grade": salesPrequalifierGrade,
        "Sales_Prequalifier_Score": salesPrequalifierScore,
        "Shop_Electric_Cost": shopElectricCost,
        "Shop_Employee_Cost": shopEmployeeCost,
        "Shop_Other_Cost": shopOtherCost,
        "Shop_Rental_Cost": shopRentalCost,
        "Shop_Transport_Cost": shopTransportCost,
        "Take_Home_Income": takeHomeIncome,
        "Take_Home_Income_wo_em_rt": takeHomeIncomeWoEmRt,
        "Total_Inventory": totalInventory,
        "Total_Purchase": totalPurchase,
        "Trust_Score": trustScore,
        "Weekly_Purchase": weeklyPurchase,
        "Weekly_Sales": weeklySales,
        "Monthly_by_Annual_Sales": monthlyByAnnualSales,
        "Monthly_by_Annual_Sales_chk": monthlyByAnnualSalesChk,
        "Monthly_by_Daily_Sales": monthlyByDailySales,
        "Monthly_by_Daily_Sales_chk": monthlyByDailySalesChk,
        "Monthly_by_Weekly_Sales": monthlyByWeeklySales,
        "Monthly_by_Weekly_Sales_chk": monthlyByWeeklySalesChk,
      };
}