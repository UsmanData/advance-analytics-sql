## Project Overview
This project applies advanced SQL analytics to historical e-commerce sales data to uncover trends, evaluate product and customer performance, and understand how revenue is distributed across the business. It builds on an earlier exploratory data analysis (EDA) project by moving from initial data exploration to deeper performance analysis and business insights.

## Business Problem
The business sells a diverse range of products to customers across multiple years. Stakeholders need to understand how sales change over time, which products perform above or below expectations, how revenue is distributed across categories, and which customer groups contribute the most value. This analysis addresses these questions to support performance monitoring, reporting, and better-informed business decisions.

## Dataset
The company’s data is structured using a star schema, consisting of:
- A Sales fact table capturing transactional details such as order dates, quantities, prices, and revenue
- Customer and Product dimension tables containing demographic and product classification information

## Tools
- **SQL** — joins, aggregations, CTEs, window functions, and analytical calculations
- **PostgreSQL** — relational database used to store and analyze the data
- **pgAdmin / Visual Studio Code** — tools used to write and execute SQL queries

## Analysis Performed
- **Change-over-Time Trends Analysis:** Examined sales patterns across months and years to identify growth periods and seasonal trends.
- **Cumulative Analysis:** Calculated running totals and cumulative sales to understand longer-term growth and changes in performance over time.
- **Performance Analysis:** Compared product performance with historical averages and prior-year results to identify stronger and weaker performers.
- **Part-to-Whole Analysis:** Measured each product category's contribution to total revenue to understand the business's revenue mix.
- **Data Segmentation:** Grouped customers by value and engagement (VIP, Regular, and New) and classified products into cost tiers for more focused analysis.

## Key Insights
- Sales analysis showed clear changes over time, with strong momentum toward year-end and a major revenue expansion phase in 2013.
- Cumulative analysis highlighted long-term growth as well as variation in performance across years.
- Product performance comparisons identified items that exceeded historical averages and products that underperformed in year-over-year comparisons.
- Bikes contributed over **96% of total revenue**, showing strong dependence on one category and potential concentration risk.
- Customer segmentation distinguished VIP, Regular, and New customer groups, while product cost tiers provided another way to compare product performance.
- Reusable reporting queries consolidated customer value, behavior, and engagement metrics for potential use in BI tools and dashboards.

## Business Recommendations
Monitor sales trends and seasonal patterns to improve planning for inventory, promotions, and reporting. Investigate the products that outperform or underperform their historical benchmarks to understand the factors behind their results. Because Bikes account for over 96% of revenue, assess the risks of category concentration and explore opportunities to grow complementary categories where supported by customer demand and profitability data. Use the customer segments to tailor retention and acquisition efforts, and continue tracking these measures over time to evaluate whether business initiatives are effective.

## Full Analysis Report
[View the complete Advance Analytics Report](report/advance_analytics_report.pdf)
