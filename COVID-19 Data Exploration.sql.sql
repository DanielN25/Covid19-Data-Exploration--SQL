SELECT *
FROM [Port Proj]..[Covid deaths]
Where continent is not null
order by 3,4

SELECT *
FROM [Port Proj]..[Covid Vaccinations] 
order by 3,4 

select Location, date, total_cases, new_cases, total_deaths, population
From [Port Proj]..[Covid deaths]
order by 1,2

SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) AS mortality_rate
FROM [Port Proj]..[Covid deaths]
ORDER BY 1, 2;


SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    ((CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100) AS mortality_rate_percentage
FROM [Port Proj]..[Covid deaths]
WHERE Location like '%Australia%'
ORDER BY 1, 2;


SELECT Location, date, population, total_cases, ((CONVERT(float, total_cases) / CONVERT(float, population)) * 100) AS mortality_rate_percentage
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
ORDER BY 1, 2;

--Looking at countries with highest infecttion rate compared to location


SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(float, total_cases) / CONVERT(float, population)) * 100) AS PercentofPopulatonInfected
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
GROUP BY Location, population
ORDER BY 1, 2;

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(float, total_cases) / CONVERT(float, population)) * 100) AS PercentofPopulatonInfected
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
GROUP BY Location, population
ORDER BY PercentofPopulatonInfected DESC


--showing the countries with the highest death count per population


SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
Where continent is not null
GROUP BY Continent
ORDER BY TotalDeathCount DESC



SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
Where continent is null
GROUP BY Continent
ORDER BY TotalDeathCount DESC

--Lets break tis down by continent

SELECT Continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
Where continent is not null
GROUP BY Continent
ORDER BY TotalDeathCount DESC


SELECT Continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
Where continent is null
GROUP BY Continent
ORDER BY TotalDeathCount DESC


--Global numbers 

SELECT date, SUM(new_cases), SUM(cast(new_deaths as int))
FROM [Port Proj]..[Covid deaths]
--WHERE Location like '%Australia%'
Group by date
ORDER BY 1, 2;

--global death percentage

SELECT 
    date, 
    SUM(new_cases) AS total_new_cases, 
    SUM(cast(new_deaths as int)) AS total_new_deaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100 
    END AS DeathPercentage
FROM [Port Proj]..[Covid deaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;



SELECT 
    SUM(new_cases) AS total_new_cases, 
    SUM(cast(new_deaths as int)) AS total_new_deaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100 
    END AS overall_death_percentage
FROM [Port Proj]..[Covid deaths]
WHERE continent IS NOT NULL;




--Covid vaccinations. 

Select *
From [Port Proj]..[Covid deaths] dea
join [Port Proj]..[Covid Vaccinations] vac
    on dea.location = vac.location 
	 and dea.date = vac.date

--looking at total population vs vaccinations


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
Sum(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) 
From [Port Proj]..[Covid deaths] dea
join [Port Proj]..[Covid Vaccinations] vac
    on dea.location = vac.location
	 and dea.date = vac.date
Where dea.continent is not null
order by 2,3


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeoplevaccinated
FROM [Port Proj]..[Covid deaths] dea
JOIN [Port Proj]..[Covid Vaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


--use CTE

With PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeoplevaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeoplevaccinated
FROM [Port Proj]..[Covid deaths] dea
JOIN [Port Proj]..[Covid Vaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date;
)
Select *, (RollingPeoplevaccinated/Population)*100
From PopvsVac

--Temp table
 
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeoplevaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    (SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100
FROM [Port Proj]..[Covid deaths] dea
JOIN [Port Proj]..[Covid Vaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

--Creating view to store data for later viz
Create View PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    (SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS RollingPercentVaccinated
FROM [Port Proj]..[Covid deaths] dea
JOIN [Port Proj]..[Covid Vaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
