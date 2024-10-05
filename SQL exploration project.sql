--Legit data for Covid Deaths

Select Location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths1
order by 1,2

-- Legit data for Covid Vaccinations



--Looking at Total Cases vs Total Deaths

SELECT Location, date, 
       CAST(total_cases AS FLOAT) AS total_cases, 
       CAST(total_deaths AS FLOAT) AS total_deaths, 
       (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths1
ORDER BY 1, 2;


-- Now in your own country
SELECT Location, date, 
       CAST(total_cases AS FLOAT) AS total_cases, 
       CAST(total_deaths AS FLOAT) AS total_deaths, 
       (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths1
WHERE location like '%states%'
ORDER BY 1, 2;

-- Total Cases vs population, shows what percent of population got COVID

SELECT Location, date, 
       CAST(population AS FLOAT) AS population, 
       CAST(total_cases AS FLOAT) AS total_cases, 
       (NULLIF(CAST(total_cases AS FLOAT), 0) / CAST(population AS FLOAT)) * 100 AS CovidPop
FROM PortfolioProject..CovidDeaths1
WHERE location like '%states%'
ORDER BY CONVERT(DATE, date, 105) ASC;   -- sql server was expecting YYYY-MM-DD and our data has DD-MM-YYYY, so converted that

-- Countries with highest infection rate, compared to respective population

SELECT Location, 
       CAST(population AS FLOAT) AS population, 
       MAX(CAST(total_cases AS FLOAT)) AS HighestInfectionCount, 
       (MAX(CAST(total_cases AS FLOAT)) / CAST(population AS FLOAT)) * 100 AS InfectionRate
FROM PortfolioProject..CovidDeaths1
GROUP BY Location, population
ORDER BY InfectionRate DESC;


-- Highest Number of cases respective country/continet/world

Select location,
		CAST(population AS FLOAT) AS population, 
		MAX(CAST(total_cases as Float)) as MostCases,
		(MAX(CAST(total_cases AS FLOAT)) / CAST(population AS FLOAT)) * 100 AS PercentagAffected
From PortfolioProject..CovidDeaths1
Group by location, population
Order by MostCases Desc;

--showing countries with the highest death count

select location, MAX(cast(total_deaths as float)) as MaxDeathCount
from PortfolioProject..CovidDeaths1
where continent is not null
	 AND location NOT IN ('World', 'High-income countries', 'Upper-middle-income countries', 
                       'Europe', 'North America', 'Asia', 'South America', 'lower-middle-income countries', 'low-income countries')
group by location
order by MaxDeathCount desc;

--showing continents with the highest death count

select continent, Max(cast(total_deaths as int)) as MaxDeathCount2
from PortfolioProject..CovidDeaths1
where continent is not null
group by continent
order by MaxDeathCount2;

--Aggregate function for global numbers (without location) (sum of new deaths and new cases seperately)

SELECT date, 
       SUM(CAST(new_cases AS FLOAT)) AS sum_cases, 
       SUM(CAST(new_deaths AS FLOAT)) AS sum_deaths, 
       (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS sum_deathpercentage
FROM PortfolioProject..CovidDeaths1
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(CAST(new_cases AS FLOAT)) > 0 --removes null values in the sum columns so that we have not nulls in sum_deathpercentage columns
ORDER BY date DESC;  

-- covidvaccinations table

select * 
from PortfolioProject..CovidVaccinations1;

--join the 2 tables and show parameters

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths1 dea
Join PortfolioProject..CovidVaccinations1 vac
	On dea.location = vac.location
where dea.continent is not null
	and dea.date = vac.date
order by 1,2;

-- using windows function (the partition) to take a look at pop vs  new vaccinations and the total/rolling vaccinations
select dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date,
dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as float)) over 
(partition by dea.location order by dea.location, dea.date) as Rollingpeoplevaccinated--doing this because the date seperates the vaccinations and sum of vaccinations
from PortfolioProject..CovidDeaths1 dea
Join PortfolioProject..CovidVaccinations1 vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by dea.location, CONVERT(DATE, dea.date, 105) desc;-- converted date from string/varchar to date format for order by to work properly


-- USE CTE- Common Table Expression - result set of a query which exists temporarily and for use only within the context of a larger query

with PopvsVac (Continent, Location, Date, Population, New_vaccinations, Rollingpeoplevaccinated)
as
(
	select dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date,
		dea.population, vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations as float)) over 
		(partition by dea.location order by dea.location, dea.date) as Rollingpeoplevaccinated
	from PortfolioProject..CovidDeaths1 dea
	Join PortfolioProject..CovidVaccinations1 vac
		On dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null
)
Select * 
from PopvsVac
order by Location, Date desc; --(use the CTE parameters for your order by no order by in inside the cte)

-- max rollingpeoplevaccinated in each location

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, Rollingpeoplevaccinated) AS (
    SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date, 
           dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS FLOAT)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rollingpeoplevaccinated
    FROM PortfolioProject..CovidDeaths1 dea
    JOIN PortfolioProject..CovidVaccinations1 vac
      ON dea.location = vac.location
      AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT Location, MAX(Rollingpeoplevaccinated) AS MaxRollingPeopleVaccinated
FROM PopvsVac
GROUP BY Location
ORDER BY MaxRollingPeopleVaccinated DESC;

--Rolling people vaccinated percentage
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, Rollingpeoplevaccinated) AS (
    SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date, 
           dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS FLOAT)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rollingpeoplevaccinated
    FROM PortfolioProject..CovidDeaths1 dea
    JOIN PortfolioProject..CovidVaccinations1 vac
      ON dea.location = vac.location
      AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
      AND dea.location NOT IN ('World', 'High-income countries', 'Upper-middle-income countries', 'Europe', 'North America', 'Asia', 'South America') -- Exclude global/aggregate data
)
SELECT Location, Population, Rollingpeoplevaccinated, 
       Least((Rollingpeoplevaccinated / Population) * 100, 100) AS VaccinationPercentage
FROM PopvsVac
ORDER BY VaccinationPercentage DESC;


-- Temp Table
CREATE TABLE population_vaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population FLOAT,
    new_vaccinations FLOAT,
    RollingpeopleVaccinated FLOAT
);

-- Insert data into the temp table
INSERT INTO population_vaccinated
SELECT dea.continent, 
       dea.location, 
       TRY_CAST(dea.date AS DATETIME) AS date,  -- Safely cast date values
       CAST(LTRIM(RTRIM(dea.population)) AS FLOAT) AS Population, 
       vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS FLOAT)) 
       OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rollingpeoplevaccinated
FROM PortfolioProject..CovidDeaths1 dea
JOIN PortfolioProject..CovidVaccinations1 vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
  AND TRY_CAST(dea.date AS DATETIME) IS NOT NULL  -- Exclude rows with invalid dates
ORDER BY dea.location, dea.date;

-- Select from the temp table
SELECT * 
FROM population_vaccinated
ORDER BY Location, Date DESC;

-- Creating view to store data for later visualisations
--USE PortfolioProject;

Create view PercentPopulation_Vaccinated as 
    SELECT dea.continent, dea.location, CONVERT(DATE, dea.date, 105) AS date, 
           dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS FLOAT)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rollingpeoplevaccinated
    FROM PortfolioProject..CovidDeaths1 dea
    JOIN PortfolioProject..CovidVaccinations1 vac
      ON dea.location = vac.location
      AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

Select * from PercentPopulation_Vaccinated


-- Creating view for covid-19 cases, deaths and vaccinations
USE PortfolioProject;
CREATE VIEW CovidCasesDeathsVaccinations AS
SELECT dea.continent, 
       dea.location, 
       CONVERT(DATE, dea.date, 105) AS date, 
       dea.population, 
       dea.total_cases, 
       dea.total_deaths,
       vac.new_vaccinations, 
       SUM(CAST(vac.new_vaccinations AS FLOAT)) 
       OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
       (CAST(dea.total_deaths AS FLOAT) / NULLIF(CAST(dea.total_cases AS FLOAT), 0)) * 100 AS DeathPercentage,
       (NULLIF(CAST(dea.total_cases AS FLOAT), 0) / CAST(dea.population AS FLOAT)) * 100 AS InfectionRate,
       (NULLIF(CAST(dea.total_deaths AS FLOAT), 0) / CAST(dea.population AS FLOAT)) * 100 AS DeathRate
FROM PortfolioProject..CovidDeaths1 dea
JOIN PortfolioProject..CovidVaccinations1 vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
  AND dea.location NOT IN 
  ('World', 'High-income countries', 'Upper-middle-income countries', 'Europe', 'North America', 'Asia', 'South America');

