#!/usr/bin/env python3
"""
Personal Finance Management Workbook Generator
================================================
Generates a professional-grade Microsoft Excel workbook for personal finance
management for a married couple, denominated in Namibian Dollar (NAD / N$).

All formula cells are protected; only input cells (light-yellow fill) are
editable.  Charts, KPIs, and summaries update automatically.

Requirements: openpyxl >= 3.1
Usage:        python generate_finance_workbook.py
Output:       Personal_Finance_Workbook.xlsx
"""

import datetime
from copy import copy

from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, PieChart, Reference
from openpyxl.chart.label import DataLabelList
from openpyxl.chart.series import DataPoint
from openpyxl.formatting.rule import CellIsRule
from openpyxl.styles import (
    Alignment,
    Border,
    Font,
    NamedStyle,
    PatternFill,
    Protection,
    Side,
    numbers,
)
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

# ──────────────────────────────────────────────
# STYLE CONSTANTS
# ──────────────────────────────────────────────
TITLE_FONT = Font(name="Calibri", size=16, bold=True, color="1F4E79")
HEADER_FONT = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
SUBHEADER_FONT = Font(name="Calibri", size=11, bold=True, color="1F4E79")
LABEL_FONT = Font(name="Calibri", size=11, bold=True, color="333333")
NORMAL_FONT = Font(name="Calibri", size=11, color="333333")
INSTRUCTION_FONT = Font(name="Calibri", size=10, italic=True, color="666666")
KPI_VALUE_FONT = Font(name="Calibri", size=14, bold=True, color="1F4E79")
KPI_LABEL_FONT = Font(name="Calibri", size=10, color="555555")

HEADER_FILL = PatternFill(start_color="1F4E79", end_color="1F4E79", fill_type="solid")
INPUT_FILL = PatternFill(start_color="FFFFCC", end_color="FFFFCC", fill_type="solid")
FORMULA_FILL = PatternFill(start_color="E8F0FE", end_color="E8F0FE", fill_type="solid")
LIGHT_GRAY_FILL = PatternFill(start_color="F2F2F2", end_color="F2F2F2", fill_type="solid")
WHITE_FILL = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
GREEN_FILL = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
YELLOW_FILL_CF = PatternFill(start_color="FFEB9C", end_color="FFEB9C", fill_type="solid")
RED_FILL = PatternFill(start_color="FFC7CE", end_color="FFC7CE", fill_type="solid")
KPI_BG_FILL = PatternFill(start_color="EBF5FB", end_color="EBF5FB", fill_type="solid")
DARK_HEADER_FILL = PatternFill(start_color="16365C", end_color="16365C", fill_type="solid")

THIN_BORDER = Border(
    left=Side(style="thin", color="B0B0B0"),
    right=Side(style="thin", color="B0B0B0"),
    top=Side(style="thin", color="B0B0B0"),
    bottom=Side(style="thin", color="B0B0B0"),
)

NAD_FORMAT = '#,##0.00" N$"'
NAD_FORMAT_PLAIN = 'N$#,##0.00'
PCT_FORMAT = "0.00%"
DATE_FORMAT = "YYYY-MM-DD"
INT_FORMAT = "#,##0"

LOCKED = Protection(locked=True)
UNLOCKED = Protection(locked=False)

CENTER = Alignment(horizontal="center", vertical="center", wrap_text=True)
LEFT_WRAP = Alignment(horizontal="left", vertical="center", wrap_text=True)
RIGHT_ALIGN = Alignment(horizontal="right", vertical="center")


# ──────────────────────────────────────────────
# HELPER FUNCTIONS
# ──────────────────────────────────────────────
def style_header_row(ws, row, max_col, font=HEADER_FONT, fill=HEADER_FILL):
    for col in range(1, max_col + 1):
        cell = ws.cell(row=row, column=col)
        cell.font = font
        cell.fill = fill
        cell.alignment = CENTER
        cell.border = THIN_BORDER
        cell.protection = LOCKED


def style_input_cell(cell, fmt=None):
    cell.fill = INPUT_FILL
    cell.font = NORMAL_FONT
    cell.border = THIN_BORDER
    cell.alignment = CENTER
    cell.protection = UNLOCKED
    if fmt:
        cell.number_format = fmt


def style_formula_cell(cell, fmt=None):
    cell.fill = FORMULA_FILL
    cell.font = NORMAL_FONT
    cell.border = THIN_BORDER
    cell.alignment = CENTER
    cell.protection = LOCKED
    if fmt:
        cell.number_format = fmt


def style_label_cell(cell, bold=True):
    cell.font = LABEL_FONT if bold else NORMAL_FONT
    cell.border = THIN_BORDER
    cell.alignment = LEFT_WRAP
    cell.protection = LOCKED


def add_title(ws, title, row=1, col=1, merge_end_col=8):
    ws.merge_cells(
        start_row=row, start_column=col, end_row=row, end_column=merge_end_col
    )
    cell = ws.cell(row=row, column=col, value=title)
    cell.font = TITLE_FONT
    cell.alignment = Alignment(horizontal="left", vertical="center")
    cell.protection = LOCKED
    ws.row_dimensions[row].height = 30


def add_instruction(ws, text, row=2, col=1, merge_end_col=8):
    ws.merge_cells(
        start_row=row, start_column=col, end_row=row, end_column=merge_end_col
    )
    cell = ws.cell(row=row, column=col, value=text)
    cell.font = INSTRUCTION_FONT
    cell.alignment = LEFT_WRAP
    cell.protection = LOCKED
    ws.row_dimensions[row].height = 20


def protect_sheet(ws, password=""):
    ws.protection.sheet = True
    ws.protection.password = password
    ws.protection.enable()


# ──────────────────────────────────────────────
# WORKBOOK CREATION
# ──────────────────────────────────────────────
wb = Workbook()

# ============================================================
# SHEET: Settings
# ============================================================
ws_settings = wb.active
ws_settings.title = "Settings"
ws_settings.sheet_properties.tabColor = "1F4E79"

add_title(ws_settings, "Settings & Configuration", merge_end_col=4)
add_instruction(
    ws_settings,
    "Update the values below. All loan calculations reference these settings automatically.",
    row=2,
    merge_end_col=4,
)

ws_settings.column_dimensions["A"].width = 5
ws_settings.column_dimensions["B"].width = 40
ws_settings.column_dimensions["C"].width = 25
ws_settings.column_dimensions["D"].width = 30

# Prime Rate
ws_settings.cell(row=4, column=2, value="Namibian Prime Lending Rate (%)").font = LABEL_FONT
ws_settings.cell(row=4, column=2).border = THIN_BORDER
ws_settings.cell(row=4, column=2).protection = LOCKED
prime_cell = ws_settings.cell(row=4, column=3, value=0.1125)
style_input_cell(prime_cell, PCT_FORMAT)
ws_settings.cell(row=4, column=4, value="Currently 11.25% as of 2024").font = INSTRUCTION_FONT

# Home Loan Margin
ws_settings.cell(row=5, column=2, value="Home Loan Margin (%)").font = LABEL_FONT
ws_settings.cell(row=5, column=2).border = THIN_BORDER
ws_settings.cell(row=5, column=2).protection = LOCKED
hl_margin = ws_settings.cell(row=5, column=3, value=0.02)
style_input_cell(hl_margin, PCT_FORMAT)
ws_settings.cell(row=5, column=4, value="Margin above prime for home loan").font = INSTRUCTION_FONT

# Vehicle Loan Margin
ws_settings.cell(row=6, column=2, value="Vehicle Loan Margin (%)").font = LABEL_FONT
ws_settings.cell(row=6, column=2).border = THIN_BORDER
ws_settings.cell(row=6, column=2).protection = LOCKED
vl_margin = ws_settings.cell(row=6, column=3, value=0.025)
style_input_cell(vl_margin, PCT_FORMAT)
ws_settings.cell(row=6, column=4, value="Margin above prime for vehicle loan").font = INSTRUCTION_FONT

# Effective Home Loan Rate
ws_settings.cell(row=8, column=2, value="Effective Home Loan Rate").font = LABEL_FONT
ws_settings.cell(row=8, column=2).border = THIN_BORDER
ws_settings.cell(row=8, column=2).protection = LOCKED
eff_hl = ws_settings.cell(row=8, column=3)
eff_hl.value = "=C4+C5"
style_formula_cell(eff_hl, PCT_FORMAT)
ws_settings.cell(row=8, column=4, value="= Prime + Home Loan Margin").font = INSTRUCTION_FONT

# Effective Vehicle Loan Rate
ws_settings.cell(row=9, column=2, value="Effective Vehicle Loan Rate").font = LABEL_FONT
ws_settings.cell(row=9, column=2).border = THIN_BORDER
ws_settings.cell(row=9, column=2).protection = LOCKED
eff_vl = ws_settings.cell(row=9, column=3)
eff_vl.value = "=C4+C6"
style_formula_cell(eff_vl, PCT_FORMAT)
ws_settings.cell(row=9, column=4, value="= Prime + Vehicle Loan Margin").font = INSTRUCTION_FONT

# Emergency fund months target
ws_settings.cell(row=11, column=2, value="Emergency Fund Target (months)").font = LABEL_FONT
ws_settings.cell(row=11, column=2).border = THIN_BORDER
ws_settings.cell(row=11, column=2).protection = LOCKED
ef_target = ws_settings.cell(row=11, column=3, value=6)
style_input_cell(ef_target, INT_FORMAT)
ws_settings.cell(row=11, column=4, value="Recommended: 3-6 months").font = INSTRUCTION_FONT

# Currency note
ws_settings.cell(row=13, column=2, value="Currency").font = LABEL_FONT
ws_settings.cell(row=13, column=2).border = THIN_BORDER
ws_settings.cell(row=13, column=3, value="NAD (N$)").font = NORMAL_FONT
ws_settings.cell(row=13, column=3).border = THIN_BORDER
ws_settings.cell(row=13, column=3).protection = LOCKED

# Legend
ws_settings.cell(row=15, column=2, value="COLOR LEGEND").font = SUBHEADER_FONT
c1 = ws_settings.cell(row=16, column=2, value="Input Cell (you type here)")
c1.fill = INPUT_FILL
c1.font = NORMAL_FONT
c1.border = THIN_BORDER
c2 = ws_settings.cell(row=17, column=2, value="Formula / Calculated Cell (auto)")
c2.fill = FORMULA_FILL
c2.font = NORMAL_FONT
c2.border = THIN_BORDER
c3 = ws_settings.cell(row=18, column=2, value="Header Row")
c3.fill = HEADER_FILL
c3.font = HEADER_FONT
c3.border = THIN_BORDER

# Define named ranges
from openpyxl.workbook.defined_name import DefinedName

wb.defined_names.add(DefinedName("PrimeRate", attr_text="Settings!$C$4"))
wb.defined_names.add(DefinedName("HomeLoanMargin", attr_text="Settings!$C$5"))
wb.defined_names.add(DefinedName("VehicleLoanMargin", attr_text="Settings!$C$6"))
wb.defined_names.add(DefinedName("EffectiveHomeLoanRate", attr_text="Settings!$C$8"))
wb.defined_names.add(DefinedName("EffectiveVehicleLoanRate", attr_text="Settings!$C$9"))
wb.defined_names.add(DefinedName("EmergencyFundMonths", attr_text="Settings!$C$11"))

protect_sheet(ws_settings)

# ============================================================
# SHEET: Income
# ============================================================
ws_income = wb.create_sheet("Income")
ws_income.sheet_properties.tabColor = "2E7D32"

add_title(ws_income, "Household Income Tracker", merge_end_col=6)
add_instruction(
    ws_income,
    "Enter all income sources below. Use the dropdowns for Person and Type. Totals update automatically.",
    row=2,
    merge_end_col=6,
)

income_headers = ["Person", "Income Source", "Type", "Amount (Monthly)", "Date", "Notes"]
header_row_income = 4
for idx, h in enumerate(income_headers, 1):
    ws_income.cell(row=header_row_income, column=idx, value=h)
style_header_row(ws_income, header_row_income, len(income_headers))

ws_income.column_dimensions["A"].width = 14
ws_income.column_dimensions["B"].width = 28
ws_income.column_dimensions["C"].width = 18
ws_income.column_dimensions["D"].width = 22
ws_income.column_dimensions["E"].width = 16
ws_income.column_dimensions["F"].width = 25

# Data validation
dv_person = DataValidation(type="list", formula1='"Me,Wife"', allow_blank=True)
dv_person.error = "Please select Me or Wife"
dv_person.errorTitle = "Invalid Person"
dv_person.prompt = "Select person"
dv_person.promptTitle = "Person"
ws_income.add_data_validation(dv_person)

dv_income_type = DataValidation(
    type="list", formula1='"Salary,Business,Passive,Rental,Investment,Other"', allow_blank=True
)
ws_income.add_data_validation(dv_income_type)

DATA_ROWS_INCOME = 50
for r in range(header_row_income + 1, header_row_income + 1 + DATA_ROWS_INCOME):
    for c in range(1, len(income_headers) + 1):
        cell = ws_income.cell(row=r, column=c)
        style_input_cell(cell)
        if c == 4:
            cell.number_format = NAD_FORMAT_PLAIN
        elif c == 5:
            cell.number_format = DATE_FORMAT
    dv_person.add(ws_income.cell(row=r, column=1))
    dv_income_type.add(ws_income.cell(row=r, column=3))

# Summary section
summary_start = header_row_income + DATA_ROWS_INCOME + 3
ws_income.merge_cells(
    start_row=summary_start, start_column=1, end_row=summary_start, end_column=4
)
ws_income.cell(row=summary_start, column=1, value="INCOME SUMMARY").font = SUBHEADER_FONT

labels_income = [
    ("My Total Income", f'=SUMIFS(D{header_row_income+1}:D{header_row_income+DATA_ROWS_INCOME},A{header_row_income+1}:A{header_row_income+DATA_ROWS_INCOME},"Me")'),
    ("Wife Total Income", f'=SUMIFS(D{header_row_income+1}:D{header_row_income+DATA_ROWS_INCOME},A{header_row_income+1}:A{header_row_income+DATA_ROWS_INCOME},"Wife")'),
    ("Combined Household Income", f"=SUM(D{header_row_income+1}:D{header_row_income+DATA_ROWS_INCOME})"),
]
for i, (label, formula) in enumerate(labels_income):
    r = summary_start + 1 + i
    lbl = ws_income.cell(row=r, column=2, value=label)
    style_label_cell(lbl)
    val = ws_income.cell(row=r, column=4)
    val.value = formula
    style_formula_cell(val, NAD_FORMAT_PLAIN)

wb.defined_names.add(
    DefinedName(
        "TotalHouseholdIncome",
        attr_text=f"Income!$D${summary_start + 3}",
    )
)

protect_sheet(ws_income)

# ============================================================
# SHEET: Expenses
# ============================================================
ws_expenses = wb.create_sheet("Expenses")
ws_expenses.sheet_properties.tabColor = "C62828"

add_title(ws_expenses, "Monthly Expense Tracker", merge_end_col=7)
add_instruction(
    ws_expenses,
    "Log all expenses. Use dropdowns for Category, Fixed/Variable, and Paid By. Summaries below update automatically.",
    row=2,
    merge_end_col=7,
)

expense_headers = [
    "Category",
    "Description",
    "Fixed/Variable",
    "Amount",
    "Date",
    "Paid By",
    "Notes",
]
header_row_exp = 4
for idx, h in enumerate(expense_headers, 1):
    ws_expenses.cell(row=header_row_exp, column=idx, value=h)
style_header_row(ws_expenses, header_row_exp, len(expense_headers))

ws_expenses.column_dimensions["A"].width = 20
ws_expenses.column_dimensions["B"].width = 30
ws_expenses.column_dimensions["C"].width = 16
ws_expenses.column_dimensions["D"].width = 18
ws_expenses.column_dimensions["E"].width = 14
ws_expenses.column_dimensions["F"].width = 14
ws_expenses.column_dimensions["G"].width = 22

EXPENSE_CATEGORIES = [
    "Housing",
    "Transport",
    "Food & Groceries",
    "Insurance",
    "Utilities",
    "Entertainment",
    "Healthcare",
    "Education",
    "Clothing",
    "Personal Care",
    "Debt Payments",
    "Subscriptions",
    "Donations",
    "Childcare",
    "Other",
]

dv_category = DataValidation(
    type="list",
    formula1='"' + ",".join(EXPENSE_CATEGORIES) + '"',
    allow_blank=True,
)
ws_expenses.add_data_validation(dv_category)

dv_fixed_var = DataValidation(type="list", formula1='"Fixed,Variable"', allow_blank=True)
ws_expenses.add_data_validation(dv_fixed_var)

dv_paid_by = DataValidation(type="list", formula1='"Me,Wife,Joint"', allow_blank=True)
ws_expenses.add_data_validation(dv_paid_by)

DATA_ROWS_EXP = 100
for r in range(header_row_exp + 1, header_row_exp + 1 + DATA_ROWS_EXP):
    for c in range(1, len(expense_headers) + 1):
        cell = ws_expenses.cell(row=r, column=c)
        style_input_cell(cell)
        if c == 4:
            cell.number_format = NAD_FORMAT_PLAIN
        elif c == 5:
            cell.number_format = DATE_FORMAT
    dv_category.add(ws_expenses.cell(row=r, column=1))
    dv_fixed_var.add(ws_expenses.cell(row=r, column=3))
    dv_paid_by.add(ws_expenses.cell(row=r, column=6))

# Expense summary by category
exp_summary_start = header_row_exp + DATA_ROWS_EXP + 3
ws_expenses.merge_cells(
    start_row=exp_summary_start, start_column=1, end_row=exp_summary_start, end_column=4
)
ws_expenses.cell(row=exp_summary_start, column=1, value="EXPENSE SUMMARY BY CATEGORY").font = SUBHEADER_FONT

ws_expenses.cell(row=exp_summary_start + 1, column=1, value="Category").font = LABEL_FONT
ws_expenses.cell(row=exp_summary_start + 1, column=1).border = THIN_BORDER
ws_expenses.cell(row=exp_summary_start + 1, column=1).fill = HEADER_FILL
ws_expenses.cell(row=exp_summary_start + 1, column=1).font = HEADER_FONT
ws_expenses.cell(row=exp_summary_start + 1, column=2, value="Total").font = LABEL_FONT
ws_expenses.cell(row=exp_summary_start + 1, column=2).border = THIN_BORDER
ws_expenses.cell(row=exp_summary_start + 1, column=2).fill = HEADER_FILL
ws_expenses.cell(row=exp_summary_start + 1, column=2).font = HEADER_FONT
ws_expenses.cell(row=exp_summary_start + 1, column=3, value="% of Total").font = LABEL_FONT
ws_expenses.cell(row=exp_summary_start + 1, column=3).border = THIN_BORDER
ws_expenses.cell(row=exp_summary_start + 1, column=3).fill = HEADER_FILL
ws_expenses.cell(row=exp_summary_start + 1, column=3).font = HEADER_FONT

for i, cat in enumerate(EXPENSE_CATEGORIES):
    r = exp_summary_start + 2 + i
    cat_cell = ws_expenses.cell(row=r, column=1, value=cat)
    style_label_cell(cat_cell, bold=False)
    total_cell = ws_expenses.cell(row=r, column=2)
    total_cell.value = f'=SUMIFS(D{header_row_exp+1}:D{header_row_exp+DATA_ROWS_EXP},A{header_row_exp+1}:A{header_row_exp+DATA_ROWS_EXP},A{r})'
    style_formula_cell(total_cell, NAD_FORMAT_PLAIN)
    pct_cell = ws_expenses.cell(row=r, column=3)
    total_exp_row = exp_summary_start + 2 + len(EXPENSE_CATEGORIES)
    pct_cell.value = f'=IF(B{total_exp_row}=0,0,B{r}/B{total_exp_row})'
    style_formula_cell(pct_cell, PCT_FORMAT)

# Grand total
grand_r = exp_summary_start + 2 + len(EXPENSE_CATEGORIES)
ws_expenses.cell(row=grand_r, column=1, value="TOTAL EXPENSES").font = LABEL_FONT
ws_expenses.cell(row=grand_r, column=1).border = THIN_BORDER
gt = ws_expenses.cell(row=grand_r, column=2)
gt.value = f"=SUM(D{header_row_exp+1}:D{header_row_exp+DATA_ROWS_EXP})"
style_formula_cell(gt, NAD_FORMAT_PLAIN)
gt.font = Font(name="Calibri", size=11, bold=True, color="C62828")

# Essential expenses total (for emergency fund)
ess_r = grand_r + 2
ws_expenses.cell(row=ess_r, column=1, value="Total Essential Expenses").font = LABEL_FONT
ws_expenses.cell(row=ess_r, column=1).border = THIN_BORDER
ws_expenses.cell(row=ess_r, column=2).font = INSTRUCTION_FONT
essential_cats = ["Housing", "Food & Groceries", "Utilities", "Insurance", "Healthcare", "Transport"]
essential_formula_parts = []
for cat in essential_cats:
    essential_formula_parts.append(
        f'SUMIFS(D{header_row_exp+1}:D{header_row_exp+DATA_ROWS_EXP},A{header_row_exp+1}:A{header_row_exp+DATA_ROWS_EXP},"{cat}")'
    )
ess_cell = ws_expenses.cell(row=ess_r, column=2)
ess_cell.value = "=" + "+".join(essential_formula_parts)
style_formula_cell(ess_cell, NAD_FORMAT_PLAIN)

wb.defined_names.add(DefinedName("TotalExpenses", attr_text=f"Expenses!$B${grand_r}"))
wb.defined_names.add(DefinedName("TotalEssentialExpenses", attr_text=f"Expenses!$B${ess_r}"))

# Conditional formatting for high-spend categories
ws_expenses.conditional_formatting.add(
    f"B{exp_summary_start+2}:B{grand_r-1}",
    CellIsRule(
        operator="greaterThan",
        formula=["5000"],
        stopIfTrue=True,
        fill=PatternFill(start_color="FFC7CE", end_color="FFC7CE", fill_type="solid"),
        font=Font(color="9C0006"),
    ),
)

protect_sheet(ws_expenses)

# ============================================================
# SHEET: Debt Tracker
# ============================================================
ws_debt = wb.create_sheet("Debt Tracker")
ws_debt.sheet_properties.tabColor = "E65100"

add_title(ws_debt, "Debt Tracker", merge_end_col=11)
add_instruction(
    ws_debt,
    "Track all debts below. Interest rate auto-calculates from Prime + Margin unless you override. All calculations are automatic.",
    row=2,
    merge_end_col=11,
)

debt_headers = [
    "Debt Type",
    "Lender",
    "Owner",
    "Original Amount",
    "Outstanding Balance",
    "Rate Mode",
    "Margin (%)",
    "Interest Rate",
    "Monthly Payment",
    "Remaining Term (mo)",
    "Monthly Interest",
    "Total Interest Left",
    "Payoff Progress (%)",
]
header_row_debt = 4
for idx, h in enumerate(debt_headers, 1):
    ws_debt.cell(row=header_row_debt, column=idx, value=h)
style_header_row(ws_debt, header_row_debt, len(debt_headers))

ws_debt.column_dimensions["A"].width = 18
ws_debt.column_dimensions["B"].width = 20
ws_debt.column_dimensions["C"].width = 10
ws_debt.column_dimensions["D"].width = 18
ws_debt.column_dimensions["E"].width = 20
ws_debt.column_dimensions["F"].width = 14
ws_debt.column_dimensions["G"].width = 12
ws_debt.column_dimensions["H"].width = 14
ws_debt.column_dimensions["I"].width = 18
ws_debt.column_dimensions["J"].width = 18
ws_debt.column_dimensions["K"].width = 18
ws_debt.column_dimensions["L"].width = 18
ws_debt.column_dimensions["M"].width = 18

dv_debt_type = DataValidation(
    type="list",
    formula1='"Credit Card,Personal Loan,Home Loan,Vehicle Loan,Student Loan,Store Credit,Other"',
    allow_blank=True,
)
ws_debt.add_data_validation(dv_debt_type)

dv_rate_mode = DataValidation(
    type="list", formula1='"Auto (Prime+Margin),Manual"', allow_blank=True
)
ws_debt.add_data_validation(dv_rate_mode)

dv_owner_debt = DataValidation(type="list", formula1='"Me,Wife,Joint"', allow_blank=True)
ws_debt.add_data_validation(dv_owner_debt)

DATA_ROWS_DEBT = 20
for r in range(header_row_debt + 1, header_row_debt + 1 + DATA_ROWS_DEBT):
    # Input cells
    for c in [1, 2, 3, 4, 5, 6, 7, 9, 10]:
        cell = ws_debt.cell(row=r, column=c)
        style_input_cell(cell)
        if c in (4, 5, 9):
            cell.number_format = NAD_FORMAT_PLAIN
        elif c == 7:
            cell.number_format = PCT_FORMAT

    dv_debt_type.add(ws_debt.cell(row=r, column=1))
    dv_owner_debt.add(ws_debt.cell(row=r, column=3))
    dv_rate_mode.add(ws_debt.cell(row=r, column=6))

    # Interest Rate (auto or manual)
    rate_cell = ws_debt.cell(row=r, column=8)
    rate_cell.value = f'=IF(F{r}="Manual",G{r},Settings!$C$4+G{r})'
    style_formula_cell(rate_cell, PCT_FORMAT)

    # Monthly Interest
    mi_cell = ws_debt.cell(row=r, column=11)
    mi_cell.value = f"=IF(E{r}=0,0,E{r}*H{r}/12)"
    style_formula_cell(mi_cell, NAD_FORMAT_PLAIN)

    # Total Interest Remaining
    ti_cell = ws_debt.cell(row=r, column=12)
    ti_cell.value = f"=IF(J{r}=0,0,K{r}*J{r})"
    style_formula_cell(ti_cell, NAD_FORMAT_PLAIN)

    # Payoff Progress
    pp_cell = ws_debt.cell(row=r, column=13)
    pp_cell.value = f"=IF(D{r}=0,0,1-(E{r}/D{r}))"
    style_formula_cell(pp_cell, PCT_FORMAT)

# Totals row
debt_total_r = header_row_debt + DATA_ROWS_DEBT + 2
ws_debt.cell(row=debt_total_r, column=1, value="TOTALS").font = LABEL_FONT
ws_debt.cell(row=debt_total_r, column=1).border = THIN_BORDER

for c, label in [(4, "D"), (5, "E"), (9, "I"), (11, "K"), (12, "L")]:
    cell = ws_debt.cell(row=debt_total_r, column=c)
    cell.value = f"=SUM({label}{header_row_debt+1}:{label}{header_row_debt+DATA_ROWS_DEBT})"
    style_formula_cell(cell, NAD_FORMAT_PLAIN)
    cell.font = Font(name="Calibri", size=11, bold=True, color="E65100")

# Debt-to-income ratio
dti_r = debt_total_r + 2
ws_debt.cell(row=dti_r, column=1, value="Debt-to-Income Ratio").font = LABEL_FONT
ws_debt.cell(row=dti_r, column=1).border = THIN_BORDER
dti_cell = ws_debt.cell(row=dti_r, column=2)
dti_cell.value = f"=IF(TotalHouseholdIncome=0,0,I{debt_total_r}/TotalHouseholdIncome)"
style_formula_cell(dti_cell, PCT_FORMAT)
ws_debt.cell(row=dti_r, column=3, value="Monthly payments / Monthly income").font = INSTRUCTION_FONT

wb.defined_names.add(DefinedName("TotalDebtOutstanding", attr_text=f"'Debt Tracker'!$E${debt_total_r}"))
wb.defined_names.add(DefinedName("TotalMonthlyDebtPayment", attr_text=f"'Debt Tracker'!$I${debt_total_r}"))

# Conditional formatting for payoff progress
ws_debt.conditional_formatting.add(
    f"M{header_row_debt+1}:M{header_row_debt+DATA_ROWS_DEBT}",
    CellIsRule(operator="greaterThanOrEqual", formula=["0.75"], fill=GREEN_FILL),
)
ws_debt.conditional_formatting.add(
    f"M{header_row_debt+1}:M{header_row_debt+DATA_ROWS_DEBT}",
    CellIsRule(operator="lessThan", formula=["0.25"], fill=RED_FILL),
)

protect_sheet(ws_debt)

# ============================================================
# SHEET: Home Loan Calculator
# ============================================================
ws_home = wb.create_sheet("Home Loan Calc")
ws_home.sheet_properties.tabColor = "4527A0"

add_title(ws_home, "Home Loan Calculator", merge_end_col=7)
add_instruction(
    ws_home,
    "Enter your property details below. The monthly repayment and amortization schedule calculate automatically using the Prime + Margin rate from Settings.",
    row=2,
    merge_end_col=7,
)

ws_home.column_dimensions["A"].width = 5
ws_home.column_dimensions["B"].width = 30
ws_home.column_dimensions["C"].width = 22
ws_home.column_dimensions["D"].width = 5
ws_home.column_dimensions["E"].width = 18
ws_home.column_dimensions["F"].width = 18
ws_home.column_dimensions["G"].width = 18
ws_home.column_dimensions["H"].width = 18
ws_home.column_dimensions["I"].width = 18

# Inputs
home_inputs = [
    ("Property Value", NAD_FORMAT_PLAIN, 2000000),
    ("Loan Amount", NAD_FORMAT_PLAIN, 1800000),
    ("Loan Term (years)", INT_FORMAT, 20),
    ("Start Date", DATE_FORMAT, datetime.date(2024, 1, 1)),
]

for i, (label, fmt, default_val) in enumerate(home_inputs):
    r = 4 + i
    ws_home.cell(row=r, column=2, value=label).font = LABEL_FONT
    ws_home.cell(row=r, column=2).border = THIN_BORDER
    ws_home.cell(row=r, column=2).protection = LOCKED
    cell = ws_home.cell(row=r, column=3, value=default_val)
    style_input_cell(cell, fmt)

# Interest Rate (from Settings)
r_rate = 8
ws_home.cell(row=r_rate, column=2, value="Interest Rate (Prime + Margin)").font = LABEL_FONT
ws_home.cell(row=r_rate, column=2).border = THIN_BORDER
ws_home.cell(row=r_rate, column=2).protection = LOCKED
rate_cell_home = ws_home.cell(row=r_rate, column=3)
rate_cell_home.value = "=EffectiveHomeLoanRate"
style_formula_cell(rate_cell_home, PCT_FORMAT)

# Outputs
r_pmt = 10
ws_home.cell(row=r_pmt, column=2, value="Monthly Repayment").font = LABEL_FONT
ws_home.cell(row=r_pmt, column=2).border = THIN_BORDER
pmt_cell = ws_home.cell(row=r_pmt, column=3)
pmt_cell.value = "=-PMT(C8/12,C6*12,C5)"
style_formula_cell(pmt_cell, NAD_FORMAT_PLAIN)
pmt_cell.font = KPI_VALUE_FONT

r_total_int = 11
ws_home.cell(row=r_total_int, column=2, value="Total Interest Payable").font = LABEL_FONT
ws_home.cell(row=r_total_int, column=2).border = THIN_BORDER
ti_home = ws_home.cell(row=r_total_int, column=3)
ti_home.value = "=C10*C6*12-C5"
style_formula_cell(ti_home, NAD_FORMAT_PLAIN)

r_total_cost = 12
ws_home.cell(row=r_total_cost, column=2, value="Total Cost of Property").font = LABEL_FONT
ws_home.cell(row=r_total_cost, column=2).border = THIN_BORDER
tc_home = ws_home.cell(row=r_total_cost, column=3)
tc_home.value = "=C5+C11"
style_formula_cell(tc_home, NAD_FORMAT_PLAIN)

# Amortization Schedule
amort_start = 14
ws_home.cell(row=amort_start, column=2, value="AMORTIZATION SCHEDULE").font = SUBHEADER_FONT

amort_headers = ["Month", "Payment", "Principal", "Interest", "Balance"]
amort_header_row = amort_start + 1
for idx, h in enumerate(amort_headers):
    ws_home.cell(row=amort_header_row, column=2 + idx, value=h)
style_header_row(ws_home, amort_header_row, 6, font=HEADER_FONT, fill=HEADER_FILL)
# Fix column range for header (cols B-F)
for c in range(2, 7):
    ws_home.cell(row=amort_header_row, column=c).fill = HEADER_FILL
    ws_home.cell(row=amort_header_row, column=c).font = HEADER_FONT

AMORT_MONTHS = 360  # 30 years max
for m in range(1, AMORT_MONTHS + 1):
    r = amort_header_row + m
    # Month
    month_cell = ws_home.cell(row=r, column=2, value=m)
    style_formula_cell(month_cell, INT_FORMAT)

    # Payment
    pay_cell = ws_home.cell(row=r, column=3)
    pay_cell.value = f"=IF(B{r}>$C$6*12,0,$C$10)"
    style_formula_cell(pay_cell, NAD_FORMAT_PLAIN)

    # Interest portion
    int_cell = ws_home.cell(row=r, column=5)
    if m == 1:
        int_cell.value = f"=IF(B{r}>$C$6*12,0,$C$5*$C$8/12)"
    else:
        int_cell.value = f"=IF(B{r}>$C$6*12,0,F{r-1}*$C$8/12)"
    style_formula_cell(int_cell, NAD_FORMAT_PLAIN)

    # Principal portion
    prin_cell = ws_home.cell(row=r, column=4)
    prin_cell.value = f"=IF(B{r}>$C$6*12,0,C{r}-E{r})"
    style_formula_cell(prin_cell, NAD_FORMAT_PLAIN)

    # Balance
    bal_cell = ws_home.cell(row=r, column=6)
    if m == 1:
        bal_cell.value = f"=IF(B{r}>$C$6*12,0,$C$5-D{r})"
    else:
        bal_cell.value = f"=IF(B{r}>$C$6*12,0,MAX(0,F{r-1}-D{r}))"
    style_formula_cell(bal_cell, NAD_FORMAT_PLAIN)

protect_sheet(ws_home)

# ============================================================
# SHEET: Vehicle Loan Calculator
# ============================================================
ws_vehicle = wb.create_sheet("Vehicle Loan Calc")
ws_vehicle.sheet_properties.tabColor = "00695C"

add_title(ws_vehicle, "Vehicle Loan Calculator", merge_end_col=7)
add_instruction(
    ws_vehicle,
    "Enter vehicle details. Monthly repayment uses Prime + Vehicle Margin from Settings. Depreciation estimate included.",
    row=2,
    merge_end_col=7,
)

ws_vehicle.column_dimensions["A"].width = 5
ws_vehicle.column_dimensions["B"].width = 30
ws_vehicle.column_dimensions["C"].width = 22
ws_vehicle.column_dimensions["D"].width = 5
ws_vehicle.column_dimensions["E"].width = 18
ws_vehicle.column_dimensions["F"].width = 18
ws_vehicle.column_dimensions["G"].width = 18
ws_vehicle.column_dimensions["H"].width = 18
ws_vehicle.column_dimensions["I"].width = 18

vehicle_inputs = [
    ("Vehicle Purchase Price", NAD_FORMAT_PLAIN, 450000),
    ("Loan Amount", NAD_FORMAT_PLAIN, 400000),
    ("Loan Term (years)", INT_FORMAT, 5),
    ("Start Date", DATE_FORMAT, datetime.date(2024, 1, 1)),
    ("Annual Depreciation Rate (%)", PCT_FORMAT, 0.15),
]

for i, (label, fmt, default_val) in enumerate(vehicle_inputs):
    r = 4 + i
    ws_vehicle.cell(row=r, column=2, value=label).font = LABEL_FONT
    ws_vehicle.cell(row=r, column=2).border = THIN_BORDER
    ws_vehicle.cell(row=r, column=2).protection = LOCKED
    cell = ws_vehicle.cell(row=r, column=3, value=default_val)
    style_input_cell(cell, fmt)

# Interest Rate (from Settings)
r_rate_v = 9
ws_vehicle.cell(row=r_rate_v, column=2, value="Interest Rate (Prime + Margin)").font = LABEL_FONT
ws_vehicle.cell(row=r_rate_v, column=2).border = THIN_BORDER
rate_cell_v = ws_vehicle.cell(row=r_rate_v, column=3)
rate_cell_v.value = "=EffectiveVehicleLoanRate"
style_formula_cell(rate_cell_v, PCT_FORMAT)

# Outputs
r_pmt_v = 11
ws_vehicle.cell(row=r_pmt_v, column=2, value="Monthly Repayment").font = LABEL_FONT
ws_vehicle.cell(row=r_pmt_v, column=2).border = THIN_BORDER
pmt_v = ws_vehicle.cell(row=r_pmt_v, column=3)
pmt_v.value = "=-PMT(C9/12,C6*12,C5)"
style_formula_cell(pmt_v, NAD_FORMAT_PLAIN)
pmt_v.font = KPI_VALUE_FONT

r_ti_v = 12
ws_vehicle.cell(row=r_ti_v, column=2, value="Total Interest Payable").font = LABEL_FONT
ws_vehicle.cell(row=r_ti_v, column=2).border = THIN_BORDER
ti_v = ws_vehicle.cell(row=r_ti_v, column=3)
ti_v.value = "=C11*C6*12-C5"
style_formula_cell(ti_v, NAD_FORMAT_PLAIN)

r_tc_v = 13
ws_vehicle.cell(row=r_tc_v, column=2, value="Total Cost of Vehicle").font = LABEL_FONT
ws_vehicle.cell(row=r_tc_v, column=2).border = THIN_BORDER
tc_v = ws_vehicle.cell(row=r_tc_v, column=3)
tc_v.value = "=C5+C12"
style_formula_cell(tc_v, NAD_FORMAT_PLAIN)

# Depreciation table
dep_start = 15
ws_vehicle.cell(row=dep_start, column=2, value="DEPRECIATION SCHEDULE").font = SUBHEADER_FONT

dep_headers = ["Year", "Estimated Value", "Depreciation Amount"]
dep_header_row = dep_start + 1
for idx, h in enumerate(dep_headers):
    ws_vehicle.cell(row=dep_header_row, column=2 + idx, value=h)
    ws_vehicle.cell(row=dep_header_row, column=2 + idx).fill = HEADER_FILL
    ws_vehicle.cell(row=dep_header_row, column=2 + idx).font = HEADER_FONT
    ws_vehicle.cell(row=dep_header_row, column=2 + idx).border = THIN_BORDER
    ws_vehicle.cell(row=dep_header_row, column=2 + idx).alignment = CENTER

for yr in range(1, 11):
    r = dep_header_row + yr
    ws_vehicle.cell(row=r, column=2, value=yr).border = THIN_BORDER
    ws_vehicle.cell(row=r, column=2).alignment = CENTER
    val_cell = ws_vehicle.cell(row=r, column=3)
    val_cell.value = f"=$C$4*(1-$C$8)^B{r}"
    style_formula_cell(val_cell, NAD_FORMAT_PLAIN)
    dep_cell = ws_vehicle.cell(row=r, column=4)
    if yr == 1:
        dep_cell.value = f"=$C$4-C{r}"
    else:
        dep_cell.value = f"=C{r-1}-C{r}"
    style_formula_cell(dep_cell, NAD_FORMAT_PLAIN)

# Vehicle amortization
v_amort_start = dep_header_row + 12
ws_vehicle.cell(row=v_amort_start, column=2, value="LOAN AMORTIZATION SCHEDULE").font = SUBHEADER_FONT

v_amort_header = v_amort_start + 1
for idx, h in enumerate(["Month", "Payment", "Principal", "Interest", "Balance"]):
    ws_vehicle.cell(row=v_amort_header, column=2 + idx, value=h)
    ws_vehicle.cell(row=v_amort_header, column=2 + idx).fill = HEADER_FILL
    ws_vehicle.cell(row=v_amort_header, column=2 + idx).font = HEADER_FONT
    ws_vehicle.cell(row=v_amort_header, column=2 + idx).border = THIN_BORDER
    ws_vehicle.cell(row=v_amort_header, column=2 + idx).alignment = CENTER

V_AMORT_MONTHS = 84  # 7 years max
for m in range(1, V_AMORT_MONTHS + 1):
    r = v_amort_header + m
    ws_vehicle.cell(row=r, column=2, value=m).border = THIN_BORDER
    ws_vehicle.cell(row=r, column=2).alignment = CENTER

    pay = ws_vehicle.cell(row=r, column=3)
    pay.value = f"=IF(B{r}>$C$6*12,0,$C$11)"
    style_formula_cell(pay, NAD_FORMAT_PLAIN)

    int_c = ws_vehicle.cell(row=r, column=5)
    if m == 1:
        int_c.value = f"=IF(B{r}>$C$6*12,0,$C$5*$C$9/12)"
    else:
        int_c.value = f"=IF(B{r}>$C$6*12,0,F{r-1}*$C$9/12)"
    style_formula_cell(int_c, NAD_FORMAT_PLAIN)

    prin = ws_vehicle.cell(row=r, column=4)
    prin.value = f"=IF(B{r}>$C$6*12,0,C{r}-E{r})"
    style_formula_cell(prin, NAD_FORMAT_PLAIN)

    bal = ws_vehicle.cell(row=r, column=6)
    if m == 1:
        bal.value = f"=IF(B{r}>$C$6*12,0,$C$5-D{r})"
    else:
        bal.value = f"=IF(B{r}>$C$6*12,0,MAX(0,F{r-1}-D{r}))"
    style_formula_cell(bal, NAD_FORMAT_PLAIN)

protect_sheet(ws_vehicle)

# ============================================================
# SHEET: Savings Tracker
# ============================================================
ws_savings = wb.create_sheet("Savings Tracker")
ws_savings.sheet_properties.tabColor = "1565C0"

add_title(ws_savings, "Savings Tracker", merge_end_col=8)
add_instruction(
    ws_savings,
    "Track all savings accounts. Goal progress and time-to-goal calculate automatically.",
    row=2,
    merge_end_col=8,
)

savings_headers = [
    "Account Name",
    "Type",
    "Current Balance",
    "Monthly Contribution",
    "Target Amount",
    "% of Goal",
    "Remaining to Goal",
    "Months to Goal",
]
header_row_sav = 4
for idx, h in enumerate(savings_headers, 1):
    ws_savings.cell(row=header_row_sav, column=idx, value=h)
style_header_row(ws_savings, header_row_sav, len(savings_headers))

ws_savings.column_dimensions["A"].width = 24
ws_savings.column_dimensions["B"].width = 18
ws_savings.column_dimensions["C"].width = 20
ws_savings.column_dimensions["D"].width = 22
ws_savings.column_dimensions["E"].width = 18
ws_savings.column_dimensions["F"].width = 14
ws_savings.column_dimensions["G"].width = 20
ws_savings.column_dimensions["H"].width = 18

dv_savings_type = DataValidation(
    type="list", formula1='"Emergency,Short-term,Long-term,Retirement"', allow_blank=True
)
ws_savings.add_data_validation(dv_savings_type)

DATA_ROWS_SAV = 20
for r in range(header_row_sav + 1, header_row_sav + 1 + DATA_ROWS_SAV):
    for c in range(1, 6):
        cell = ws_savings.cell(row=r, column=c)
        style_input_cell(cell)
        if c in (3, 4, 5):
            cell.number_format = NAD_FORMAT_PLAIN
    dv_savings_type.add(ws_savings.cell(row=r, column=2))

    # % of goal
    pct = ws_savings.cell(row=r, column=6)
    pct.value = f"=IF(E{r}=0,0,MIN(1,C{r}/E{r}))"
    style_formula_cell(pct, PCT_FORMAT)

    # Remaining
    rem = ws_savings.cell(row=r, column=7)
    rem.value = f"=IF(E{r}=0,0,MAX(0,E{r}-C{r}))"
    style_formula_cell(rem, NAD_FORMAT_PLAIN)

    # Months to goal
    mtg = ws_savings.cell(row=r, column=8)
    mtg.value = f'=IF(OR(D{r}=0,G{r}<=0),"N/A",ROUNDUP(G{r}/D{r},0))'
    style_formula_cell(mtg)

# Totals
sav_total_r = header_row_sav + DATA_ROWS_SAV + 2
ws_savings.cell(row=sav_total_r, column=1, value="TOTALS").font = LABEL_FONT
ws_savings.cell(row=sav_total_r, column=1).border = THIN_BORDER
for c in [3, 4, 5]:
    cell = ws_savings.cell(row=sav_total_r, column=c)
    col_letter = get_column_letter(c)
    cell.value = f"=SUM({col_letter}{header_row_sav+1}:{col_letter}{header_row_sav+DATA_ROWS_SAV})"
    style_formula_cell(cell, NAD_FORMAT_PLAIN)
    cell.font = Font(name="Calibri", size=11, bold=True, color="1565C0")

wb.defined_names.add(DefinedName("TotalSavings", attr_text=f"'Savings Tracker'!$C${sav_total_r}"))

# Conditional formatting for goal %
ws_savings.conditional_formatting.add(
    f"F{header_row_sav+1}:F{header_row_sav+DATA_ROWS_SAV}",
    CellIsRule(operator="greaterThanOrEqual", formula=["1"], fill=GREEN_FILL),
)
ws_savings.conditional_formatting.add(
    f"F{header_row_sav+1}:F{header_row_sav+DATA_ROWS_SAV}",
    CellIsRule(operator="lessThan", formula=["0.5"], fill=RED_FILL),
)

protect_sheet(ws_savings)

# ============================================================
# SHEET: Investments
# ============================================================
ws_invest = wb.create_sheet("Investments")
ws_invest.sheet_properties.tabColor = "6A1B9A"

add_title(ws_invest, "Investment Portfolio Tracker", merge_end_col=9)
add_instruction(
    ws_invest,
    "Track all investments. Gain/loss and weighted return calculate automatically.",
    row=2,
    merge_end_col=9,
)

invest_headers = [
    "Investment Type",
    "Platform",
    "Initial Investment",
    "Current Value",
    "Monthly Contribution",
    "Expected Return (% p.a.)",
    "Gain / Loss",
    "Gain / Loss (%)",
    "Notes",
]
header_row_inv = 4
for idx, h in enumerate(invest_headers, 1):
    ws_invest.cell(row=header_row_inv, column=idx, value=h)
style_header_row(ws_invest, header_row_inv, len(invest_headers))

ws_invest.column_dimensions["A"].width = 20
ws_invest.column_dimensions["B"].width = 20
ws_invest.column_dimensions["C"].width = 20
ws_invest.column_dimensions["D"].width = 18
ws_invest.column_dimensions["E"].width = 22
ws_invest.column_dimensions["F"].width = 24
ws_invest.column_dimensions["G"].width = 18
ws_invest.column_dimensions["H"].width = 16
ws_invest.column_dimensions["I"].width = 22

dv_invest_type = DataValidation(
    type="list",
    formula1='"Stocks,ETF,Property,Retirement Fund,Unit Trust,Bonds,Crypto,Other"',
    allow_blank=True,
)
ws_invest.add_data_validation(dv_invest_type)

DATA_ROWS_INV = 20
for r in range(header_row_inv + 1, header_row_inv + 1 + DATA_ROWS_INV):
    for c in range(1, 7):
        cell = ws_invest.cell(row=r, column=c)
        style_input_cell(cell)
        if c in (3, 4, 5):
            cell.number_format = NAD_FORMAT_PLAIN
        elif c == 6:
            cell.number_format = PCT_FORMAT
    # Notes also input
    ws_invest.cell(row=r, column=9).protection = UNLOCKED
    ws_invest.cell(row=r, column=9).fill = INPUT_FILL
    ws_invest.cell(row=r, column=9).border = THIN_BORDER

    dv_invest_type.add(ws_invest.cell(row=r, column=1))

    # Gain/Loss
    gl = ws_invest.cell(row=r, column=7)
    gl.value = f"=IF(C{r}=0,0,D{r}-C{r})"
    style_formula_cell(gl, NAD_FORMAT_PLAIN)

    # Gain/Loss %
    glp = ws_invest.cell(row=r, column=8)
    glp.value = f"=IF(C{r}=0,0,G{r}/C{r})"
    style_formula_cell(glp, PCT_FORMAT)

# Totals
inv_total_r = header_row_inv + DATA_ROWS_INV + 2
ws_invest.cell(row=inv_total_r, column=1, value="TOTALS").font = LABEL_FONT
ws_invest.cell(row=inv_total_r, column=1).border = THIN_BORDER

for c in [3, 4, 5, 7]:
    cell = ws_invest.cell(row=inv_total_r, column=c)
    col_letter = get_column_letter(c)
    cell.value = f"=SUM({col_letter}{header_row_inv+1}:{col_letter}{header_row_inv+DATA_ROWS_INV})"
    style_formula_cell(cell, NAD_FORMAT_PLAIN)
    cell.font = Font(name="Calibri", size=11, bold=True, color="6A1B9A")

# Weighted return
wr_r = inv_total_r + 2
ws_invest.cell(row=wr_r, column=1, value="Weighted Expected Return").font = LABEL_FONT
ws_invest.cell(row=wr_r, column=1).border = THIN_BORDER
wr = ws_invest.cell(row=wr_r, column=2)
wr.value = f"=IF(D{inv_total_r}=0,0,SUMPRODUCT(D{header_row_inv+1}:D{header_row_inv+DATA_ROWS_INV},F{header_row_inv+1}:F{header_row_inv+DATA_ROWS_INV})/D{inv_total_r})"
style_formula_cell(wr, PCT_FORMAT)

wb.defined_names.add(DefinedName("TotalInvestments", attr_text=f"Investments!$D${inv_total_r}"))

# Conditional formatting for gain/loss
ws_invest.conditional_formatting.add(
    f"G{header_row_inv+1}:G{header_row_inv+DATA_ROWS_INV}",
    CellIsRule(operator="greaterThan", formula=["0"], fill=GREEN_FILL),
)
ws_invest.conditional_formatting.add(
    f"G{header_row_inv+1}:G{header_row_inv+DATA_ROWS_INV}",
    CellIsRule(operator="lessThan", formula=["0"], fill=RED_FILL),
)

protect_sheet(ws_invest)

# ============================================================
# SHEET: Emergency Fund
# ============================================================
ws_emerg = wb.create_sheet("Emergency Fund")
ws_emerg.sheet_properties.tabColor = "D84315"

add_title(ws_emerg, "Emergency Fund Tracker", merge_end_col=5)
add_instruction(
    ws_emerg,
    "Your emergency fund target is calculated from essential expenses (linked from Expenses sheet). Update your current emergency savings below.",
    row=2,
    merge_end_col=5,
)

ws_emerg.column_dimensions["A"].width = 5
ws_emerg.column_dimensions["B"].width = 38
ws_emerg.column_dimensions["C"].width = 25
ws_emerg.column_dimensions["D"].width = 25
ws_emerg.column_dimensions["E"].width = 20

# Monthly essential expenses
ws_emerg.cell(row=4, column=2, value="Monthly Essential Expenses").font = LABEL_FONT
ws_emerg.cell(row=4, column=2).border = THIN_BORDER
ess_link = ws_emerg.cell(row=4, column=3)
ess_link.value = "=TotalEssentialExpenses"
style_formula_cell(ess_link, NAD_FORMAT_PLAIN)
ws_emerg.cell(row=4, column=4, value="Linked from Expenses sheet").font = INSTRUCTION_FONT

# Target months
ws_emerg.cell(row=5, column=2, value="Target Months of Expenses").font = LABEL_FONT
ws_emerg.cell(row=5, column=2).border = THIN_BORDER
tm = ws_emerg.cell(row=5, column=3)
tm.value = "=EmergencyFundMonths"
style_formula_cell(tm)
ws_emerg.cell(row=5, column=4, value="Set in Settings sheet").font = INSTRUCTION_FONT

# Emergency fund target (3 months)
ws_emerg.cell(row=7, column=2, value="Emergency Fund Target (3 months)").font = LABEL_FONT
ws_emerg.cell(row=7, column=2).border = THIN_BORDER
ef3 = ws_emerg.cell(row=7, column=3)
ef3.value = "=C4*3"
style_formula_cell(ef3, NAD_FORMAT_PLAIN)

# Emergency fund target (6 months)
ws_emerg.cell(row=8, column=2, value="Emergency Fund Target (6 months)").font = LABEL_FONT
ws_emerg.cell(row=8, column=2).border = THIN_BORDER
ef6 = ws_emerg.cell(row=8, column=3)
ef6.value = "=C4*6"
style_formula_cell(ef6, NAD_FORMAT_PLAIN)

# Emergency fund target (custom)
ws_emerg.cell(row=9, column=2, value="Emergency Fund Target (custom from Settings)").font = LABEL_FONT
ws_emerg.cell(row=9, column=2).border = THIN_BORDER
ef_custom = ws_emerg.cell(row=9, column=3)
ef_custom.value = "=C4*C5"
style_formula_cell(ef_custom, NAD_FORMAT_PLAIN)

# Current emergency savings
ws_emerg.cell(row=11, column=2, value="Current Emergency Savings").font = LABEL_FONT
ws_emerg.cell(row=11, column=2).border = THIN_BORDER
cur_sav = ws_emerg.cell(row=11, column=3, value=0)
style_input_cell(cur_sav, NAD_FORMAT_PLAIN)
ws_emerg.cell(row=11, column=4, value="Enter your current emergency fund balance").font = INSTRUCTION_FONT

# % of target reached
ws_emerg.cell(row=13, column=2, value="% of Target Reached").font = LABEL_FONT
ws_emerg.cell(row=13, column=2).border = THIN_BORDER
pct_reached = ws_emerg.cell(row=13, column=3)
pct_reached.value = "=IF(C9=0,0,C11/C9)"
style_formula_cell(pct_reached, PCT_FORMAT)

# Months covered
ws_emerg.cell(row=14, column=2, value="Months of Expenses Covered").font = LABEL_FONT
ws_emerg.cell(row=14, column=2).border = THIN_BORDER
months_cov = ws_emerg.cell(row=14, column=3)
months_cov.value = '=IF(C4=0,0,ROUND(C11/C4,1))'
style_formula_cell(months_cov)

# Shortfall
ws_emerg.cell(row=15, column=2, value="Shortfall / Surplus").font = LABEL_FONT
ws_emerg.cell(row=15, column=2).border = THIN_BORDER
shortfall = ws_emerg.cell(row=15, column=3)
shortfall.value = "=C11-C9"
style_formula_cell(shortfall, NAD_FORMAT_PLAIN)

# Status
ws_emerg.cell(row=17, column=2, value="FUND STATUS").font = SUBHEADER_FONT
ws_emerg.cell(row=17, column=2).border = THIN_BORDER
status_cell = ws_emerg.cell(row=17, column=3)
status_cell.value = '=IF(C14>=6,"FULLY FUNDED",IF(C14>=3,"ON TRACK (3-6 months)","UNDERFUNDED"))'
style_formula_cell(status_cell)
status_cell.font = Font(name="Calibri", size=14, bold=True)

# Conditional formatting for status
ws_emerg.conditional_formatting.add(
    "C17",
    CellIsRule(
        operator="equal",
        formula=['"FULLY FUNDED"'],
        fill=GREEN_FILL,
        font=Font(color="006100", bold=True, size=14),
    ),
)
ws_emerg.conditional_formatting.add(
    "C17",
    CellIsRule(
        operator="equal",
        formula=['"ON TRACK (3-6 months)"'],
        fill=YELLOW_FILL_CF,
        font=Font(color="9C6500", bold=True, size=14),
    ),
)
ws_emerg.conditional_formatting.add(
    "C17",
    CellIsRule(
        operator="equal",
        formula=['"UNDERFUNDED"'],
        fill=RED_FILL,
        font=Font(color="9C0006", bold=True, size=14),
    ),
)

wb.defined_names.add(DefinedName("CurrentEmergencySavings", attr_text="'Emergency Fund'!$C$11"))

protect_sheet(ws_emerg)

# ============================================================
# SHEET: Dashboard
# ============================================================
ws_dash = wb.create_sheet("Dashboard", 0)  # Insert at position 0
ws_dash.sheet_properties.tabColor = "0D47A1"

add_title(ws_dash, "Personal Finance Dashboard", merge_end_col=10)
add_instruction(
    ws_dash,
    "This dashboard updates automatically from all other sheets. No input needed here.",
    row=2,
    merge_end_col=10,
)

ws_dash.column_dimensions["A"].width = 3
ws_dash.column_dimensions["B"].width = 28
ws_dash.column_dimensions["C"].width = 22
ws_dash.column_dimensions["D"].width = 3
ws_dash.column_dimensions["E"].width = 28
ws_dash.column_dimensions["F"].width = 22
ws_dash.column_dimensions["G"].width = 3
ws_dash.column_dimensions["H"].width = 28
ws_dash.column_dimensions["I"].width = 22
ws_dash.column_dimensions["J"].width = 3

# ── KPI Cards ──
kpi_data = [
    # (label, formula, row, col_label, col_value, fmt)
    ("Total Monthly Income", "=TotalHouseholdIncome", 4, 2, 3, NAD_FORMAT_PLAIN),
    ("Total Monthly Expenses", "=TotalExpenses", 4, 5, 6, NAD_FORMAT_PLAIN),
    ("Net Cash Flow", "=TotalHouseholdIncome-TotalExpenses", 4, 8, 9, NAD_FORMAT_PLAIN),
    ("Total Debt Outstanding", "=TotalDebtOutstanding", 7, 2, 3, NAD_FORMAT_PLAIN),
    ("Total Savings", "=TotalSavings", 7, 5, 6, NAD_FORMAT_PLAIN),
    ("Total Investments", "=TotalInvestments", 7, 8, 9, NAD_FORMAT_PLAIN),
    ("Emergency Fund Status", "='Emergency Fund'!C13", 10, 2, 3, PCT_FORMAT),
    ("Savings Rate", "=IF(TotalHouseholdIncome=0,0,(TotalHouseholdIncome-TotalExpenses)/TotalHouseholdIncome)", 10, 5, 6, PCT_FORMAT),
    ("Debt-to-Income Ratio", f"='Debt Tracker'!B{dti_r}", 10, 8, 9, PCT_FORMAT),
]

for label, formula, row, cl, cv, fmt in kpi_data:
    # Background for KPI card area
    for c in [cl, cv]:
        ws_dash.cell(row=row, column=c).fill = KPI_BG_FILL
        ws_dash.cell(row=row, column=c).border = THIN_BORDER
        ws_dash.cell(row=row + 1, column=c).fill = KPI_BG_FILL
        ws_dash.cell(row=row + 1, column=c).border = THIN_BORDER

    lbl = ws_dash.cell(row=row, column=cl, value=label)
    lbl.font = KPI_LABEL_FONT
    lbl.alignment = LEFT_WRAP
    lbl.protection = LOCKED

    val = ws_dash.cell(row=row + 1, column=cl)
    ws_dash.merge_cells(start_row=row + 1, start_column=cl, end_row=row + 1, end_column=cv)
    val.value = formula
    val.font = KPI_VALUE_FONT
    val.number_format = fmt
    val.alignment = Alignment(horizontal="center", vertical="center")
    val.protection = LOCKED

# Net Worth
nw_row = 13
ws_dash.merge_cells(start_row=nw_row, start_column=2, end_row=nw_row, end_column=3)
ws_dash.cell(row=nw_row, column=2, value="NET WORTH").font = SUBHEADER_FONT
ws_dash.cell(row=nw_row, column=2).border = THIN_BORDER

ws_dash.merge_cells(start_row=nw_row, start_column=5, end_row=nw_row, end_column=6)
nw_label = ws_dash.cell(row=nw_row, column=5, value="Assets - Liabilities")
nw_label.font = KPI_LABEL_FONT
nw_label.border = THIN_BORDER

ws_dash.merge_cells(start_row=nw_row + 1, start_column=2, end_row=nw_row + 1, end_column=6)
nw_val = ws_dash.cell(row=nw_row + 1, column=2)
nw_val.value = "=TotalSavings+TotalInvestments-TotalDebtOutstanding"
nw_val.font = Font(name="Calibri", size=18, bold=True, color="0D47A1")
nw_val.number_format = NAD_FORMAT_PLAIN
nw_val.alignment = Alignment(horizontal="center", vertical="center")
nw_val.fill = KPI_BG_FILL
nw_val.border = THIN_BORDER
nw_val.protection = LOCKED

# Budget vs Actual header
bva_row = 16
ws_dash.merge_cells(start_row=bva_row, start_column=2, end_row=bva_row, end_column=6)
ws_dash.cell(row=bva_row, column=2, value="MONTHLY BUDGET vs ACTUAL (Top Categories)").font = SUBHEADER_FONT

# Conditional formatting for Net Cash Flow (green if positive, red if negative)
ws_dash.conditional_formatting.add(
    f"H5:I5",
    CellIsRule(operator="greaterThan", formula=["0"], fill=GREEN_FILL),
)
ws_dash.conditional_formatting.add(
    f"H5:I5",
    CellIsRule(operator="lessThan", formula=["0"], fill=RED_FILL),
)

# ── CHARTS ──

# 1. Expense Breakdown Pie Chart
# We need a data range for the pie chart. Use the expense summary from Expenses sheet.
pie = PieChart()
pie.title = "Expense Breakdown by Category"
pie.style = 10
pie.width = 18
pie.height = 12

# Categories are in Expenses!A{exp_summary_start+2}:A{exp_summary_start+1+len(EXPENSE_CATEGORIES)}
# Values are in Expenses!B{exp_summary_start+2}:B{exp_summary_start+1+len(EXPENSE_CATEGORIES)}
cat_ref = Reference(
    ws_expenses,
    min_col=1,
    min_row=exp_summary_start + 2,
    max_row=exp_summary_start + 1 + len(EXPENSE_CATEGORIES),
)
val_ref = Reference(
    ws_expenses,
    min_col=2,
    min_row=exp_summary_start + 2,
    max_row=exp_summary_start + 1 + len(EXPENSE_CATEGORIES),
)
pie.add_data(val_ref)
pie.set_categories(cat_ref)
pie.dataLabels = DataLabelList()
pie.dataLabels.showPercent = True
pie.dataLabels.showCatName = True
pie.dataLabels.showVal = False

ws_dash.add_chart(pie, "B18")

# 2. Income vs Expenses Bar Chart
bar = BarChart()
bar.type = "col"
bar.title = "Income vs Expenses"
bar.style = 10
bar.width = 14
bar.height = 12
bar.y_axis.title = "Amount (N$)"

# Create a small data table for the bar chart on dashboard (hidden area)
ws_dash.cell(row=40, column=2, value="Category").protection = LOCKED
ws_dash.cell(row=40, column=3, value="Amount").protection = LOCKED
ws_dash.cell(row=41, column=2, value="Income").protection = LOCKED
ws_dash.cell(row=41, column=3, value="=TotalHouseholdIncome").protection = LOCKED
ws_dash.cell(row=41, column=3).number_format = NAD_FORMAT_PLAIN
ws_dash.cell(row=42, column=2, value="Expenses").protection = LOCKED
ws_dash.cell(row=42, column=3, value="=TotalExpenses").protection = LOCKED
ws_dash.cell(row=42, column=3).number_format = NAD_FORMAT_PLAIN
ws_dash.cell(row=43, column=2, value="Net Cash Flow").protection = LOCKED
ws_dash.cell(row=43, column=3, value="=TotalHouseholdIncome-TotalExpenses").protection = LOCKED
ws_dash.cell(row=43, column=3).number_format = NAD_FORMAT_PLAIN
ws_dash.cell(row=44, column=2, value="Debt Payments").protection = LOCKED
ws_dash.cell(row=44, column=3, value="=TotalMonthlyDebtPayment").protection = LOCKED
ws_dash.cell(row=44, column=3).number_format = NAD_FORMAT_PLAIN
ws_dash.cell(row=45, column=2, value="Savings").protection = LOCKED
ws_dash.cell(row=45, column=3, value="=TotalSavings").protection = LOCKED
ws_dash.cell(row=45, column=3).number_format = NAD_FORMAT_PLAIN

bar_cats = Reference(ws_dash, min_col=2, min_row=41, max_row=45)
bar_vals = Reference(ws_dash, min_col=3, min_row=40, max_row=45)
bar.add_data(bar_vals, titles_from_data=True)
bar.set_categories(bar_cats)
bar.shape = 4

ws_dash.add_chart(bar, "F18")

# 3. Net Worth Trend Line Chart (placeholder data table for user to fill monthly)
nw_trend_start = 48
ws_dash.cell(row=nw_trend_start, column=2, value="NET WORTH TREND (Monthly Tracking)").font = SUBHEADER_FONT
ws_dash.cell(row=nw_trend_start + 1, column=2, value="Month").font = HEADER_FONT
ws_dash.cell(row=nw_trend_start + 1, column=2).fill = HEADER_FILL
ws_dash.cell(row=nw_trend_start + 1, column=2).border = THIN_BORDER
ws_dash.cell(row=nw_trend_start + 1, column=3, value="Net Worth").font = HEADER_FONT
ws_dash.cell(row=nw_trend_start + 1, column=3).fill = HEADER_FILL
ws_dash.cell(row=nw_trend_start + 1, column=3).border = THIN_BORDER
ws_dash.cell(row=nw_trend_start + 1, column=4, value="Income").font = HEADER_FONT
ws_dash.cell(row=nw_trend_start + 1, column=4).fill = HEADER_FILL
ws_dash.cell(row=nw_trend_start + 1, column=4).border = THIN_BORDER
ws_dash.cell(row=nw_trend_start + 1, column=5, value="Expenses").font = HEADER_FONT
ws_dash.cell(row=nw_trend_start + 1, column=5).fill = HEADER_FILL
ws_dash.cell(row=nw_trend_start + 1, column=5).border = THIN_BORDER

months_list = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
]
for i, month in enumerate(months_list):
    r = nw_trend_start + 2 + i
    ws_dash.cell(row=r, column=2, value=month).border = THIN_BORDER
    ws_dash.cell(row=r, column=2).alignment = CENTER
    ws_dash.cell(row=r, column=2).protection = LOCKED
    for c in [3, 4, 5]:
        cell = ws_dash.cell(row=r, column=c)
        style_input_cell(cell, NAD_FORMAT_PLAIN)

line = LineChart()
line.title = "Net Worth / Income / Expenses Trend"
line.style = 10
line.width = 22
line.height = 12
line.y_axis.title = "Amount (N$)"
line.x_axis.title = "Month"

nw_cats = Reference(ws_dash, min_col=2, min_row=nw_trend_start + 2, max_row=nw_trend_start + 13)
nw_vals = Reference(ws_dash, min_col=3, max_col=5, min_row=nw_trend_start + 1, max_row=nw_trend_start + 13)
line.add_data(nw_vals, titles_from_data=True)
line.set_categories(nw_cats)

# Style the line series
for idx, series in enumerate(line.series):
    if idx == 0:  # Net Worth
        series.graphicalProperties.line.width = 25000
    elif idx == 1:  # Income
        series.graphicalProperties.line.dashStyle = "dash"
    elif idx == 2:  # Expenses
        series.graphicalProperties.line.dashStyle = "dot"

ws_dash.add_chart(line, "B35")

protect_sheet(ws_dash)

# ============================================================
# FINAL: Move Settings to the end, order sheets
# ============================================================
# Current order: Dashboard, Settings, Income, Expenses, Debt Tracker,
#   Home Loan Calc, Vehicle Loan Calc, Savings Tracker, Investments, Emergency Fund
# Desired: Dashboard, Income, Expenses, Debt Tracker, Home Loan Calc,
#   Vehicle Loan Calc, Savings Tracker, Investments, Emergency Fund, Settings

desired_order = [
    "Dashboard",
    "Income",
    "Expenses",
    "Debt Tracker",
    "Home Loan Calc",
    "Vehicle Loan Calc",
    "Savings Tracker",
    "Investments",
    "Emergency Fund",
    "Settings",
]
sheet_indices = {name: i for i, name in enumerate(wb.sheetnames)}
new_order = [sheet_indices[name] for name in desired_order]
wb.move_sheet("Settings", offset=len(wb.sheetnames) - 1 - wb.sheetnames.index("Settings"))

# ============================================================
# SAVE
# ============================================================
OUTPUT_PATH = "/home/ubuntu/repos/Opportunities-Namibia/Personal_Finance_Workbook.xlsx"
wb.save(OUTPUT_PATH)
print(f"Workbook saved to {OUTPUT_PATH}")
print(f"Sheets: {wb.sheetnames}")
