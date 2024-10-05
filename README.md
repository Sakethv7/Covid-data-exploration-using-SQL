COVID-19 Analysis using SQL
This project performs data analysis on COVID-19 cases, deaths, and vaccinations using SQL. It leverages various SQL techniques like JOINs, PARTITION BY, WINDOW FUNCTIONS, and VIEWS to analyze the relationship between cases, deaths, and vaccination rates across different countries and continents.
Dataset
The project uses two datasets:
1.	CovidDeaths1: Contains data about total cases, new cases, total deaths, and population statistics.
2.	CovidVaccinations1: Contains data about the number of new vaccinations administered.
Analysis Performed
1. COVID-19 Cases vs Deaths
•	This query analyzes the percentage of deaths compared to the total number of cases on a per-location basis. It also computes death rates over time.
SELECT Location, date, 
    CAST(total_cases AS FLOAT) AS total_cases, 
    CAST(total_deaths AS FLOAT) AS total_deaths, 
    (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths1
ORDER BY Location, date;
2. COVID-19 Infections Compared to Population
•	This query calculates the percentage of the population that has been infected with COVID-19 in each country.
SELECT Location, date, 
    CAST(population AS FLOAT) AS population, 
    CAST(total_cases AS FLOAT) AS total_cases, 
    (NULLIF(CAST(total_cases AS FLOAT), 0) / CAST(population AS FLOAT)) * 100 AS CovidPop
FROM PortfolioProject..CovidDeaths1
WHERE location like '%states%'
ORDER BY CONVERT(DATE, date, 105) ASC;
3. Countries with the Highest Infection Rates
•	This query identifies the countries with the highest infection rates by comparing the highest number of total cases against the population.
SELECT Location, 
    CAST(population AS FLOAT) AS population, 
    MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount, 
    (MAX(CAST(total_cases AS FLOAT)) / CAST(population AS FLOAT)) * 100 AS InfectionRate
FROM PortfolioProject..CovidDeaths1
GROUP BY Location, population
ORDER BY InfectionRate DESC;
4. Rolling Sum of Vaccinations (Window Function)
•	The PARTITION BY and WINDOW FUNCTION are used to calculate the rolling sum of vaccinations in each location.
SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date,
    dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as float)) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rollingpeoplevaccinated
FROM PortfolioProject..CovidDeaths1 dea
JOIN PortfolioProject..CovidVaccinations1 vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, CONVERT(DATE, dea.date, 105) desc;
5. Views for Reusability
•	To simplify future queries and for better visualizations, views were created to store calculated results like rolling vaccinations, infection rates, and death rates.
CREATE VIEW PercentPopulation_Vaccinated AS 
    SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date, 
        dea.population, vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS FLOAT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rollingpeoplevaccinated
    FROM PortfolioProject..CovidDeaths1 dea
    JOIN PortfolioProject..CovidVaccinations1 vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL;
How to Run the SQL Queries
1.	Clone this repository:
git clone https://github.com/your-username/your-repo-name.git
2.	Import the SQL file into your preferred SQL environment (SQL Server, MySQL, etc.). The queries are written for SQL Server, but with slight modifications, they should work with other SQL systems.
3.	Use the provided queries to analyze the relationship between COVID-19 cases, deaths, and vaccinations.
4.	The queries are designed to be modular and easy to modify for additional insights. For example, you can modify the WHERE clauses to focus on specific regions or time periods.
Features Used
•	Window Functions (PARTITION BY): To compute rolling sums of vaccinations.
•	Joins: To merge data from the COVID deaths and vaccination tables.
•	Views: To store complex queries for easy access in future queries or visualizations.
•	Aggregate Functions: To compute metrics like total deaths, cases, vaccination percentages, and infection rates.
Potential Extensions
•	Integrate with a visualization tool like Power BI or Tableau to create interactive dashboards.
•	Add more granular filtering, such as date ranges, specific continents, or countries.
•	Incorporate additional metrics, like hospitalizations, recovered cases, etc.

