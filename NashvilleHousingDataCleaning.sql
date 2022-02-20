/* Você é um analista de dados e foi requerido que você explorasse esta base de dados de vendas de imóveis em Nashville, Tennessee, EUA. Porém, ao verificar as primeiras 1000
linhas da base, você constatou que precisaria realizar um serviço à parte de limpeza dos dados.

Seu objetivo por tanto é realizar uma limpeza e transformação dos dados para aí sim começarem os trabalhos de exploração e descrição dos dados.
*/

/* Link para o Dataset: https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx */

/* Iniciamos o projeto clicando com o botão direito na tabela NashvilleHouse e escolhendo a opção "Selecionar as primeiras 1000 linhas". Ao explorar os atributos e registros
da tabela, foram constatados os seguintes problemas:
1. A coluna SaleDate está com um formato que tem além da data, tem hora, minuto, segundo e milissegundo, que são informações desnecessárias para nosso proposito.
2. Na coluna PropertyAddress, as informações do endereço se misturam com o nome da cidade (no caso, Goodlettsville), vamos separar estas informações
3. Na coluna OwnerAddress, as informações estão juntas como endereço, cidade e estado. Para melhorar a exploração dos dados, vamos separar também estas informações.
4. Na coluna SoldAsVacant, há apenas duas respostas (Yes ou No), mas também há as informações Y e N, vamos converter tudo para Yes e No, para que haja apenas dois filtros.
5. Remover duplicatas
6. Remover colunas que não estão sendo usadas.

Um pequeno disclaimer: como boa prática de bancos de dados, não é recomendado deletar dados brutos direto na base, sejam colunas ou linhas. É melhor
que estes trabalhos sejam realizados numa tabela separada ou no momento de criar as visualizações com Python, Power BI ou outra ferramenta.

As operações que farei aqui são por motivos didáticos. Não apague registros no banco de dados que está na produção.
Beleza? Então vamos começar. */

SELECT * FROM PortfolioProjects.dbo.NashvilleHouse

/* 1. Mudando o formato da Data 
A data está em um formato com a data, mas com hora, minuto, segundo e milissegundo, não precisamos desta informação
*/

ALTER TABLE NashvilleHouse
ADD SaleDateClean Date;
UPDATE NashvilleHouse
SET SaleDateClean = CONVERT(Date, SaleDate)

/* Criamos uma nova coluna com a data limpa, vamos ver como ela ficou: */
SELECT SaleDateClean FROM PortfolioProjects.dbo.NashvilleHouse

/* 2. Separando Endereço e Cidade */

SELECT PropertyAddress FROM PortfolioProjects.dbo.NashvilleHouse
WHERE PropertyAddress IS NULL

--Vamos olhar um pouco mais de perto--
SELECT * FROM PortfolioProjects.dbo.NashvilleHouse
ORDER BY ParcelID

/* Percebemos que há valores duplicados no ParcelID, algumas vezes um deles terá endereço e o outro não, então faremos os seguinte
Se existir um registro duplicado e este registro tiver endereço e o outro não, inclua o endereço no registro que não tem endereço.
Para isso, precisamos realizar um JOIN com a tabela e ela mesma, para verificarmos todos os valores que tem o ID duplicado */

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHouse A
JOIN PortfolioProjects.dbo.NashvilleHouse B
	ON A.ParcelID =  B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

/* O UniqueID aparece como forma de garantir que ele nao vai pegar a mesma linha.
O preenchimento será com a função ISNULL, ou seja, se a.PropertyAddress for NULL, preencha com b.PropertyAddress
Com o preenchimento feito, vamos realizar o UPDATE: */

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress) 
FROM PortfolioProjects.dbo.NashvilleHouse A
JOIN PortfolioProjects.dbo.NashvilleHouse B
	ON A.ParcelID =  B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

-- Vamos realizar o check para ver se ainda há endereços NULLs
SELECT PropertyAddress FROM PortfolioProjects.dbo.NashvilleHouse
WHERE PropertyAddress IS NULL

-- Não há mais endereços nulos, podemos seguir em frente.

/* 3. Quebrando o Endereço em Colunas Individuais	 */
SELECT PropertyAddress FROM PortfolioProjects.dbo.NashvilleHouse

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS City

FROM PortfolioProjects.dbo.NashvilleHouse

/* A Substring retornou o index de onde fica a vírgula e trouxe apenas o texto até ela, criando uma nova coluna chamada Address */
/* Com as querys funcionando, podemos alterar a tabela: */
ALTER TABLE NashvilleHouse
ADD SplitAddress nvarchar(255), SplitCity nvarchar(255);

UPDATE NashvilleHouse
SET SplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )
FROM PortfolioProjects.dbo.NashvilleHouse


UPDATE NashvilleHouse
SET SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))
FROM PortfolioProjects.dbo.NashvilleHouse

-- O mesmo vai valer para a coluna OwnerAddress, mas desta vez vamos utilizar outro método, o PARSENAME
SELECT PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM PortfolioProjects.dbo.NashvilleHouse

-- Com as queries funcionando, vamos adicionar as colunas
ALTER TABLE NashvilleHouse
ADD SplitOwnerAddress nvarchar(255), SplitOwnerCity nvarchar(255), SplitOwnerState nvarchar(5);

UPDATE NashvilleHouse
SET SplitOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
SplitOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
SplitOwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM PortfolioProjects.dbo.NashvilleHouse

/* 4. Trocando Y e N por Yes e No 
Vamos verificar como está a coluna SoldAsVacant */

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) FROM PortfolioProjects.dbo.NashvilleHouse
GROUP BY SoldAsVacant

/* Percebe-se que há 4 informações, pois o Sim e o Não estão representados de duas formas diferentes cada, Yes e Y vs No e N. Y e N representam
mais de 400 registros, prejudicando parte da análise, vamos mudar esta coluna para que fique apenas dois valores: Yes e No */

UPDATE NashvilleHouse
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

/* Realizado o UPDATE, vamos verificar se funcionou utilizando o mesmo select do início da questão: */
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) FROM PortfolioProjects.dbo.NashvilleHouse
GROUP BY SoldAsVacant

/* 5. Remover Duplicatas
A ideia de ter uma linha duplicada segue esta lógica: Se um imóvel tem o mesmo ID, endereço, preço de venda, data de venda e documento legal,
pode-se presumir que trata-se de uma informação duplicada, representado na base de dados como ParcelID, PropertyAddress, SalePrice, SaleDate e
LegalReference, então vamos partir os dados atribuindo índices de linha, se houver algum registro com o número 2, significa que este registro
está com os mesmos parâmetros que inserimos no PARTITION */

WITH RowNumCTE AS(
Select *, ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID) row_num
	
From PortfolioProjects.dbo.NashvilleHouse
)
/* Você perceberá que algumas linhas estão com o row_num 2, implicando, segundo os nossos critérios, que trata-se de um registro duplicado */
DELETE FROM RowNumCTE
WHERE row_num > 1

/* Agora não deverá haver mais registro duplicados. */
SELECT * FROM RowNumCTE
WHERE row_num > 1

/* 6. Remover as colunas que não serão mais usadas.

Ratificando o dito no disclaimer: nao é recomendado apagar registros brutos no banco de dados de produção, o faremos agora por razões didáticas.
No caso após fazermos todas as alterações dos itens anteriores, haverão colunas que já foram tratadas e não serão mais necessárias, a saber:
*/

ALTER TABLE NashvilleHouse
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate

-- Veremos agora como ficou nossa base:
SELECT * FROM NashvilleHouse

/* Agora temos nossa base limpa e pronta para análise. 
Muito obrigado por ter apreciado meu projeto!
Fique à vontade para conferir outros projetos no meu GitHub ou visitar meu perfil no LinkedIn.
Um grande abraço!
*/


