/*
Covid-19 Data Exploration (For Egypt)

Skills used: 
- Joins
- CTEs (Common Table Expressions)
- Temporary Tables
- Window Functions
- Aggregate Functions
- Creating Views
- Data Type Conversions

Dataset: Analyzing Covid-19 data focusing on Egypt, comparing global statistics, and determining trends related to vaccination impact.

*/

-- 1. View all data from Deaths Table for non-null continents
SELECT * 
FROM Covid19Analysis..Deaths$
WHERE continent IS NOT NULL
ORDER BY location, date;

-- 2. View all data from Vaccination Table
SELECT * 
FROM Covid19Analysis..Vaccination$
ORDER BY location, date;

-- 3. Check for missing data in population, total_cases, or total_deaths
SELECT location, date, total_cases, total_deaths, population 
FROM Covid19Analysis..Deaths$
WHERE total_cases IS NULL 
   OR total_deaths IS NULL 
   OR population IS NULL;

-- 4. Select Covid-19 related data for non-null continents
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM Covid19Analysis..Deaths$
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- 5. Calculate death percentage in Egypt
SELECT location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM Covid19Analysis..Deaths$
WHERE location = 'Egypt'
  AND total_cases <> 0  -- Avoid division by zero
ORDER BY date;

-- 6. Total Cases vs Population: Percentage of population infected
SELECT location, date, total_cases, population, 
       (total_cases / population) * 100 AS InfectedPercentage
FROM Covid19Analysis..Deaths$
ORDER BY location, date;

-- 7. Countries with the highest infection rate compared to population
SELECT location, population, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population)) * 100 AS InfectedPercentage
FROM Covid19Analysis..Deaths$
GROUP BY location, population
ORDER BY InfectedPercentage DESC;

-- 8. Countries with the highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid19Analysis..Deaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 9. Continents with the highest death count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid19Analysis..Deaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 10. Compare Egypt to countries with similar population size
SELECT location, population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX(total_deaths) AS TotalDeathCount
FROM Covid19Analysis..Deaths$
WHERE population BETWEEN 50000000 AND 150000000
GROUP BY location, population
ORDER BY HighestInfectionCount DESC;

-- 11. Global summary of new cases and deaths with death percentage
SELECT SUM(new_cases) AS TotalCases, 
       SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
       SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM Covid19Analysis..Deaths$
WHERE continent IS NOT NULL;

-- 12. Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM Covid19Analysis..Deaths$ dea
JOIN Covid19Analysis..Vaccination$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- 13. Trend of new cases over time in Egypt
SELECT date, new_cases
FROM Covid19Analysis..Deaths$
WHERE location = 'Egypt'
ORDER BY date;

-- 14. Clean invalid data in the Vaccination table
UPDATE Covid19Analysis..Vaccination$
SET new_vaccinations = NULL
WHERE TRY_CONVERT(INT, new_vaccinations) IS NULL;

-- 15. Alter column type for consistent data format
ALTER TABLE Covid19Analysis..Vaccination$
ALTER COLUMN new_vaccinations INT;

-- 16. Analyze the impact of vaccinations on Covid cases and deaths in Egypt
SELECT dea.date, 
       SUM(new_cases) AS TotalCases, 
       SUM(new_deaths) AS TotalDeaths, 
       SUM(vac.new_vaccinations) AS TotalVaccinations
FROM Covid19Analysis..Deaths$ dea
JOIN Covid19Analysis..Vaccination$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'Egypt'
GROUP BY dea.date
ORDER BY dea.date;

-- 17. Impact of Covid-19 across African regions
SELECT location, SUM(total_cases) AS TotalCases, SUM(total_deaths) AS TotalDeaths
FROM Covid19Analysis..Deaths$
WHERE continent = 'Africa'
GROUP BY location
ORDER BY TotalCases DESC;

-- 18. Use CTE to calculate the percentage of vaccinated population
WITH PopVsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM Covid19Analysis..Deaths$ dea
    JOIN Covid19Analysis..Vaccination$ vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM PopVsVac;

-- 19. Temporary table to store calculated vaccination percentages
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM Covid19Analysis..Deaths$ dea
JOIN Covid19Analysis..Vaccination$ vac ON dea.location = vac.location AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated;

-- 20. Create a view to store vaccination data for visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM Covid19Analysis..Deaths$ dea
JOIN Covid19Analysis..Vaccination$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
