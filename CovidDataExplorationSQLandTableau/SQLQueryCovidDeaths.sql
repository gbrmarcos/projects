/* O trabalho em questão analisará os dados sobre mortes e vacinações da COVID-19 nos países do G20 desde o primeiro caso até 28 de fevereiro
de 2022.

O G20 é um grupo formado pelos ministros de finanças e chefes dos bancos centrais das 19 maiores economias do mundo mais a União Europeia.

O G-20 estuda, analisa e promove a discussão entre os países mais ricos e os emergentes sobre questões políticas relacionadas com a promoção 
da estabilidade financeira internacional e encaminha as questões que estão além das responsabilidades individuais de qualquer organização.

Os dados foram retirados do site Our World in Data, uma das melhores plataformas de dados socioeconômicos do mundo.
Fonte: https://ourworldindata.org/covid-deaths

Originalmente, trata-se de apenas um arquivo .csv, porém para faciliar os trabalho, dividimos o arquivo em dois: um para avaliar as mortes
por COVID-19 e outro para avaliar as vacinações.

Vamos iniciar verificando os dados brutos. */
SELECT * FROM CovidStats.DBO.CovidDeaths

/* Temos uma coluna para identificação de total de casos (total_cases) e outra para total de morte (total_death), é interessante criar uma
coluna para definição da porcentagem de mortes em relação ao número de casos, para verificar a variação deste número durante o tempo. */
SELECT (total_deaths/total_cases) FROM CovidStats.DBO.CovidDeaths
/* Opa! Encontramos um problema, uma das variáveis está como nvarchar, portanto é impossível realizar uma divisão, vamos mudar isso agora mesmo. */
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_deaths DECIMAL(18,0)
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_cases DECIMAL(18,0)
GO 

/* Com o erro resolvido, teremos a proporção de mortes por casos totais em todos os locais, mas vamos olhar para o Brasil primeiro.
A multiplicação por 100 será para obter o valor por porcentagem.*/
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage FROM CovidStats.DBO.CovidDeaths
WHERE location LIKE 'Brazil'
ORDER BY 1,2

/* Podemos observar que a taxa de mortalidade da COVID-19 no Brasil em 2022 fica entre 2,25% e 2,75%, mas este percentual já foi quase 4%
de acordo com os dados de julho de 2020, o primeiro pico da pandemia no Brasil. 

2.0 Vamos analisar agora o total de casos por população, analisando apenas os países do G20. A título de informação, os países do G20 são:
África do Sul, Argentina, Brasil, Canadá, Estados Unidos, México, China, Japão, Coreia do Sul, Índia, Indonésia, Arábia Saudita, Turquia,
Alemanha, França, Itália, Rússia, Reino Unido e Austrália.

Como os dados trazidos são todos os países do mundo, vamos criar uma tabela temporária para trabalhar apenas com os dados do G20. */
SELECT * INTO dbo.CovidDeathsG20
FROM CovidStats.DBO.CovidDeathsG20 
WHERE location IN ('South Africa', 'Argentina', 'Brazil', 'Canada', 'United States','Mexico', 'China',
'Japan', 'South Korea', 'India', 'Indonesia', 'Saudi Arabia', 'Turkey', 'Germany', 'France', 'Italy', 
'Russia', 'United Kingdom', 'Australia');

/* Agora poderemos trabalhar com a nossa tabela do G20. O objetivo é saber qual a % da população relativa que pegou COVID, lembrando que existe
a possibilidade da mesma pessoa pegar a doença mais de uma vez. */
SELECT location, max(total_cases) AS TotalCases, max(population) AS population, ROUND((max(total_cases)/max(population))*100,2) as CasesPercentage
FROM CovidStats.DBO.CovidDeathsG20 
GROUP BY location
ORDER BY 4

/* Temos que a China é o país mais bem colocado, com apenas 0,007% da população, seguido de Indonésia (2,01%), Arábia Saudita (2,10%)
e Índia (3,08%). Como piores resultados temos Estados Unidos (23,74%), Reino Unido (27,76%) e França (33,75%). */

/* Olhando agora para a porcentagem de mortes, para ver se o padrão se mantém. */
SELECT location, max(total_deaths) AS TotalDeaths, max(population) AS population, round((max(total_deaths)/max(population))*100,4) as DeathPercentage
FROM CovidStats.DBO.CovidDeathsG20 
GROUP BY location
ORDER BY 4

/* O país com menos mortes proporcionais é a China, seguindo a tendência da análises dos dados, com apenas 0,0003% da população morta por COVID-19.
Seguido de Coreia do Sul (0,01%), Japão (0,018%) e Austrália (0,02%). Pode-se concluir que mesmo os países não tendo os menores índices de casos,
provavelmente tem um melhor sistema de saúde para cuidar das pessoas infectadas, resultando em menos mortes.

Do outro lado, o Brasil tem o pior resultado de mortes, 0,30% da população morreu de COVID-19, seguido dos Estados Unidos (0,28%), são dois países
que lidaram com sobrecargas no sistema de Saúde, ambos pela negligência e falta de estrutura para receber pacientes, resultando em mais mortes,
mesmo com menos casos proporcionais, olhando para o Brasil. 

Mas como poderíamos saber qual foi o maior pico de casos da pandemia no G20 até hoje? Vamos verificar:

Bem como na primeira query, será necessário alterar as colunas new_deaths and new_cases para decimal.*/
ALTER TABLE CovidStats.dbo.CovidDeathsG20 ALTER COLUMN new_deaths DECIMAL(18,0)
ALTER TABLE CovidStats.dbo.CovidDeathsG20 ALTER COLUMN new_cases DECIMAL(18,0)
GO 
-- Vamos também mudar o formato da data, para tornar algo mais legível:
ALTER TABLE CovidStats.dbo.CovidDeathsG20
ADD DateClean Date;
UPDATE CovidStats.dbo.CovidDeathsG20
SET DateClean = CONVERT(Date, date)

SELECT DateClean, SUM(CAST(new_cases AS int)) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidStats.DBO.CovidDeathsG20
GROUP BY DateClean
ORDER BY 2 DESC

/* É possível observar que o dia 19 de janeiro de 2022 foi o maior recorde de casos entre os países do G20, com 2 milhões e 885 mil novos casos.
A tendência se mantém, já que o 20 dias com maiores números de novos casos ocorreram todos em 2022, mostrando o tamanho do impacto da variante ômicron
considerada mais transmissível do que todas as outras já registradas. 
O pico de casos em 2021 foi no dia 30 de dezembro, com 1,4 milhão de casos e em 2020, foram registrados 613 mil casos em 31 de dezembro deste ano. 
*/

/* Vamos passar para a tabela de testes e vacinações do G20: */
SELECT * INTO CovidStats.dbo.CovidVaxG20
FROM CovidStats.DBO.CovidVax 
WHERE location IN ('South Africa', 'Argentina', 'Brazil', 'Canada', 'United States','Mexico', 'China',
'Japan', 'South Korea', 'India', 'Indonesia', 'Saudi Arabia', 'Turkey', 'Germany', 'France', 'Italy', 
'Russia', 'United Kingdom', 'Australia');
/* Vamos utilizar um JOIN para trazer as duas tabelas (Vax e Deaths), olhando para a vacinação total.

Gostaríamos de saber qual foi o primeiro país do G20 a iniciar a vacinação, vamos utilizar uma função para isso. */

SELECT D.location, MIN(D.DateClean) AS FirstVaxDate
FROM CovidStats.dbo.CovidDeathsG20 D
JOIN CovidVaxG20 V
	ON D.location = V.location
	AND D.date = V.date
WHERE V.total_vaccinations IS NOT NULL
GROUP BY d.location
ORDER BY 2
/* O primeiro país a vacinar a sua população foram os Estados Unidos no dia 13 de dezembro de 2020, seguidos por Canada no dia 14 e China e Rússia
no dia 15. Os últimos países a iniciarem a vacinação foram Japão no dia 17 de fevereiro de 2021, Austrália em 21 de fevereiro e Coreia do Sul dia
26 de fevereiro. Pode-se observar exemplos de países com baixo índice de Mortes, como Japão e Austrália não tiveram tanta pressa em iniciar a 
vacinação como os Estados Unidos, até hoje o país com maior índice de mortes. */

/* Para finalizar, vamos criar a primeira visualização dentro do próprio SQL Server, no caso, vamos obter o percentual de pessoas vacinadas
por país. Esta visualização será o percentual de pessoas vacinadas no país. Como já conhecemos o problema que iremos ter, vamos alterar a coluna
new_vaccinations como decimal */

ALTER TABLE CovidStats.dbo.CovidVaxG20 ALTER COLUMN new_vaccinations DECIMAL(18,0)

CREATE VIEW PercentualPopulationVaccinated AS
Select D.continent, D.location, D.DateClean, D.population, V.new_vaccinations
, SUM(CONVERT(bigint,V.new_vaccinations)) OVER (PARTITION BY D.Location ORDER BY D.location, D.DateClean) as RollingPeopleVaccinated
FROM CovidStats.dbo.CovidDeathsG20 D
JOIN CovidStats.dbo.CovidVaxG20 V
	On d.location = V.location
	and D.date = V.date
where D.continent is not null 

