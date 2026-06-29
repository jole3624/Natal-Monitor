function natal_mat_app()
    % NATAL-MAT - Dashboard Clinica Nazionale - VERSIONE CORRETTA E COMPATIBILE
    
    %% ====================================================================
    %% 1. INIZIALIZZAZIONE E SICUREZZA FILE
    %% ====================================================================
    dbFile = 'natal_mat.db';
    fattoreScala = 2200; 
    
    if exist('conn','var')
        %#ok<*TRYNC>
        try close(conn); catch; end
    end
    
    if exist(dbFile, 'file')
        try
            delete(dbFile);
        catch
            error('Il file del database è bloccato da MATLAB. Scrivi "clear all" nella Command Window e riprova.');
        end
    end
    
    conn = sqlite(dbFile, 'create');
    
    exec(conn, ['CREATE TABLE IF NOT EXISTS Pazienti (' ...
                'ID_Paziente INTEGER PRIMARY KEY, ' ...
                'Regione TEXT, ' ...
                'Eta_Madre INTEGER, ' ...
                'Cittadinanza TEXT)']);
            
    exec(conn, ['CREATE TABLE IF NOT EXISTS Eventi_Nascita (' ...
                'ID_Parto INTEGER PRIMARY KEY, ' ...
                'ID_Paziente INTEGER, ' ...
                'Peso INTEGER, ' ...
                'Settimane_Gestazione INTEGER, ' ...
                'Tipo_Parto TEXT, ' ...
                'Apgar INTEGER, ' ...
                'Data_Parto TEXT, ' ...
                'Anno_Parto INTEGER, ' ... 
                'Mese_Parto INTEGER, ' ... 
                'Sesso TEXT, ' ... 
                'FOREIGN KEY(ID_Paziente) REFERENCES Pazienti(ID_Paziente))']);
            
    exec(conn, ['CREATE TABLE IF NOT EXISTS Diagnosi (' ...
                'ID_Diagnosi INTEGER PRIMARY KEY, ' ...
                'ID_Parto INTEGER, ' ...
                'Patologia TEXT, ' ... 
                'FOREIGN KEY(ID_Parto) REFERENCES Eventi_Nascita(ID_Parto))']);

    %% ====================================================================
    %% 2. POPOLAMENTO ALGORITMICO (CORRETTO REFUSO DIAGNOSI)
    %% ====================================================================
    rng(42); 
    regioni = {'Lombardia', 'Lazio', 'Campania', 'Veneto', 'Emilia-Romagna', ...
               'Piemonte', 'Toscana', 'Sicilia', 'Puglia', 'Liguria', ...
               'Marche', 'Abruzzo', 'Friuli-Venezia Giulia', 'Trentino-Alto Adige', ...
               'Umbria', 'Basilicata', 'Molise', 'Valle d''Aosta', 'Sardegna', 'Calabria'};
           
    cittadinanze = {'Italiana', 'Italiana', 'Italiana', 'Europea', 'Extra-UE'};
    tipiParto = {'Naturale', 'Naturale', 'Cesareo'};
    anniDisponibili = {'2021', '2022', '2023', '2024', '2025', '2026'};
    sessi = {'Maschio', 'Femmina'};
    
    numRecord = 1600; 
    
    for i = 1:numRecord
        regione = regioni{randi(length(regioni))};
        eta = round(32 + 4 * randn());
        if eta < 15; eta = 15; elseif eta > 50; eta = 50; end
        cit = cittadinanze{randi(length(cittadinanze))};
        
        regioneSQL = strrep(regione, '''', '''''');
        exec(conn, sprintf('INSERT INTO Pazienti (ID_Paziente, Regione, Eta_Madre, Cittadinanza) VALUES (%d, ''%s'', %d, ''%s'')', i, regioneSQL, eta, cit));
        
        probPrematuro = (eta > 40 || eta < 21) * 0.15 + 0.07;
        if rand() < probPrematuro
            settimane = randi([26, 36]);
            peso = randi([950, 2450]);
            apgar = randi([4, 8]);
        else
            settimane = randi([37, 42]);
            peso = randi([2550, 4250]);
            apgar = randi([8, 10]);
        end
        tipo = tipiParto{randi(length(tipiParto))};
        sesso = sessi{randi(length(sessi))};
        
        anno = randi([2021, 2026]);
        if anno == 2026; mese = randi([1, 6]); else; mese = randi([1, 12]); end
        giorno = randi([1, 28]); 
        dataParto = sprintf('%04d-%02d-%02d', anno, mese, giorno);
        
        exec(conn, sprintf('INSERT INTO Eventi_Nascita (ID_Parto, ID_Paziente, Peso, Settimane_Gestazione, Tipo_Parto, Apgar, Data_Parto, Anno_Parto, Mese_Parto, Sesso) VALUES (%d, %d, %d, %d, ''%s'', %d, ''%s'', %d, %d, ''%s'')', ...
            i, i, peso, settimane, tipo, apgar, dataParto, anno, mese, sesso));
        
        % CORRETTO: rimosso l'ultimo "semanas" latente che bloccava il popolamento delle diagnosi
        if settimane < 32
            exec(conn, sprintf('INSERT INTO Diagnosi (ID_Parto, Patologia) VALUES (%d, ''Prematurità Grave'')', i));
        elseif settimane < 37
            exec(conn, sprintf('INSERT INTO Diagnosi (ID_Parto, Patologia) VALUES (%d, ''Prematurità Moderata'')', i));
        end
        if apgar < 7
            exec(conn, sprintf('INSERT INTO Diagnosi (ID_Parto, Patologia) VALUES (%d, ''Distress Respiratorio'')', i));
        end
        if peso < 1500
            exec(conn, sprintf('INSERT INTO Diagnosi (ID_Parto, Patologia) VALUES (%d, ''Deficit di Crescita Fetale'')', i));
        end
        if rand() < 0.07
            exec(conn, sprintf('INSERT INTO Diagnosi (ID_Parto, Patologia) VALUES (%d, ''Ittero Neonatale'')', i));
        end
    end
    close(conn);

    %% ====================================================================
    %% 3. INTERFACCIA GRAFICA AD ALTO CONTRASTO (DARK MODE)
    %% ====================================================================
    fig = uifigure('Name', 'NATAL-MAT - Dashboard Clinica Nazionale', 'Position', [50, 50, 1250, 780]);
    fig.Color = [0.12, 0.12, 0.14]; 
    
    tabGroup = uitabgroup(fig, 'Position', [10, 10, 1230, 760]);
    tab1 = uitab(tabGroup, 'Title', 'Dashboard Nazionale');
    tab2 = uitab(tabGroup, 'Title', 'Dettaglio e Trend Temporali Regionali');
    
    % --- SCHEDA 1: DASHBOARD NAZIONALE ---
    pnlKPI = uipanel(tab1, 'Title', 'KPI NAZIONALI (SCALA REALE)', 'Position', [20, 20, 280, 610], ...
                     'BackgroundColor', [0.18, 0.18, 0.22], 'FontWeight', 'bold', 'ForegroundColor', [1 1 1]);
    
    conn = sqlite(dbFile);
    valNascite = myExtractScalar(fetch(conn, 'SELECT COUNT(*) FROM Eventi_Nascita')) * fattoreScala;
    valEtaNaz = myExtractScalar(fetch(conn, 'SELECT AVG(Eta_Madre) FROM Pazienti'));
    valCesNaz = myExtractScalar(fetch(conn, 'SELECT (COUNT(*)*100.0)/(SELECT COUNT(*) FROM Eventi_Nascita) FROM Eventi_Nascita WHERE Tipo_Parto=''Cesareo'''));
    valPremNaz = myExtractScalar(fetch(conn, 'SELECT (COUNT(*)*100.0)/(SELECT COUNT(*) FROM Eventi_Nascita) FROM Eventi_Nascita WHERE Settimane_Gestazione < 37'));
    
    uilabel(tab1, 'Position', [20, 650, 1130, 30], 'Text', 'Periodo Storico Analizzato: dal 2021 al 2026', 'FontSize', 16, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    
    uilabel(pnlKPI, 'Position', [20, 520, 240, 20], 'Text', 'Nascite Totali Stimate:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    uilabel(pnlKPI, 'Position', [20, 485, 240, 35], 'Text', num2str(valNascite), 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [0.30, 0.75, 1.0]);
    
    uilabel(pnlKPI, 'Position', [20, 390, 240, 20], 'Text', 'Età Media Madre:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    uilabel(pnlKPI, 'Position', [20, 355, 240, 35], 'Text', sprintf('%.1f anni', valEtaNaz), 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [1, 1, 1]);
    
    uilabel(pnlKPI, 'Position', [20, 260, 240, 20], 'Text', 'Tasso Tagli Cesarei:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    uilabel(pnlKPI, 'Position', [20, 225, 240, 35], 'Text', sprintf('%.1f%%', valCesNaz), 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [1, 0.4, 0.4]);
    
    uilabel(pnlKPI, 'Position', [20, 130, 240, 20], 'Text', 'Tasso Nati Prematuri:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    uilabel(pnlKPI, 'Position', [20, 95, 240, 35], 'Text', sprintf('%.1f%%', valPremNaz), 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [1, 0.75, 0.2]);
    
    axNasciteReg = uiaxes(tab1, 'Position', [330, 335, 850, 290]);
    axCittadinanza = uiaxes(tab1, 'Position', [330, 15, 850, 290]);
    
    [regNames, regCounts] = mySplitData(fetch(conn, 'SELECT Regione, COUNT(*) FROM Pazienti GROUP BY Regione'));
    bar(axNasciteReg, categorical(string(regNames)), regCounts * fattoreScala, 'FaceColor', [0.15, 0.55, 0.85]);
    
    [citNames, citCounts] = mySplitData(fetch(conn, 'SELECT Cittadinanza, COUNT(*) FROM Pazienti GROUP BY Cittadinanza'));
    pie(axCittadinanza, citCounts, string(citNames));
    close(conn);
    
    % --- SCHEDA 2: DETTAGLIO REGIONALE + FILTRI ---
    uilabel(tab2, 'Position', [20, 620, 120, 22], 'Text', 'Regione:', 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    ddRegione = uidropdown(tab2, 'Position', [90, 620, 160, 22], 'Items', regioni);
    
    uilabel(tab2, 'Position', [280, 620, 60, 22], 'Text', 'Anno:', 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    ddAnno = uidropdown(tab2, 'Position', [330, 620, 90, 22], 'Items', anniDisponibili);
    
    ddRegione.ValueChangedFcn = @(dd, event) updateRegionalStats(ddRegione.Value, ddAnno.Value);
    ddAnno.ValueChangedFcn = @(dd, event) updateRegionalStats(ddRegione.Value, ddAnno.Value);
                         
    pnlRegStats = uipanel(tab2, 'Title', 'METRICHE ANNUALI FILTRATE', 'Position', [20, 20, 360, 580], ...
                         'BackgroundColor', [0.18, 0.18, 0.22], 'FontWeight', 'bold', 'ForegroundColor', [1 1 1]);
    
    lblRegNascite = uilabel(pnlRegStats, 'Position', [20, 510, 320, 25], 'Text', '', 'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    lblRegEta = uilabel(pnlRegStats, 'Position', [20, 455, 320, 25], 'Text', '', 'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    lblRegCesarei = uilabel(pnlRegStats, 'Position', [20, 400, 320, 25], 'Text', '', 'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [1, 0.4, 0.4]);
    lblRegPrematuri = uilabel(pnlRegStats, 'Position', [20, 345, 320, 25], 'Text', '', 'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [1, 0.75, 0.2]);
    
    uilabel(pnlRegStats, 'Position', [20, 250, 320, 20], 'Text', 'Incidenza Patologie Reali:', 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    tblDiagnosi = uitable(pnlRegStats, 'Position', [10, 15, 340, 220], 'ColumnName', {'Patologia Riconosciuta', 'Casi Stimi'});
    
    axRegTrendMensile = uiaxes(tab2, 'Position', [410, 395, 410, 210]); 
    axRegSesso = uiaxes(tab2, 'Position', [840, 395, 360, 210]); 
    axRegPatologie = uiaxes(tab2, 'Position', [410, 20, 790, 340]);     
    
    configDarkAxes(axNasciteReg, 'Distribuzione Nazionale Nascite');
    configDarkAxes(axCittadinanza, 'Ripartizione Cittadinanza');
    configDarkAxes(axRegTrendMensile, 'Andamento Mensile');
    configDarkAxes(axRegSesso, 'Ripartizione Genere');
    configDarkAxes(axRegPatologie, 'Frequenza Patologie Neonatali');
    
    updateRegionalStats(regioni{1}, anniDisponibili{1});

    %% ====================================================================
    %% 4. CALLBACK DI AGGIORNAMENTO DINAMICO
    %% ====================================================================
    function updateRegionalStats(selectedRegion, selectedYear)
        localDbFile = 'natal_mat.db';
        localFattore = 2200;
        
        c = sqlite(localDbFile);
        regionSQL = strrep(selectedRegion, '''', '''''');
        annoNum = str2double(selectedYear);
        
        r1 = fetch(c, sprintf('SELECT COUNT(*) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d', regionSQL, annoNum));
        r2 = fetch(c, sprintf('SELECT AVG(P.Eta_Madre) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d', regionSQL, annoNum));
        r3 = fetch(c, sprintf(['SELECT (COUNT(*)*100.0)/(SELECT COUNT(*) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente=E.ID_Paziente WHERE P.Regione=''%s'' AND E.Anno_Parto=%d) ' ...
                               'FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente=E.ID_Paziente WHERE P.Regione=''%s'' AND E.Anno_Parto=%d AND E.Tipo_Parto=''Cesareo'''], regionSQL, annoNum, regionSQL, annoNum));
        r4 = fetch(c, sprintf(['SELECT (COUNT(*)*100.0)/(SELECT COUNT(*) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente=E.ID_Paziente WHERE P.Regione=''%s'' AND E.Anno_Parto=%d) ' ...
                               'FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente=E.ID_Paziente WHERE P.Regione=''%s'' AND E.Anno_Parto=%d AND E.Settimane_Gestazione < 37'], regionSQL, annoNum, regionSQL, annoNum));
                           
        rMesi = fetch(c, sprintf(['SELECT E.Mese_Parto, COUNT(*) FROM Eventi_Nascita E ' ...
                                  'JOIN Pazienti P ON E.ID_Paziente = P.ID_Paziente ' ...
                                  'WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d GROUP BY E.Mese_Parto ORDER BY E.Mese_Parto ASC'], regionSQL, annoNum));
        
        rSesso = fetch(c, sprintf(['SELECT E.Sesso, COUNT(*) FROM Eventi_Nascita E ' ...
                                   'JOIN Pazienti P ON E.ID_Paziente = P.ID_Paziente ' ...
                                   'WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d GROUP BY E.Sesso'], regionSQL, annoNum));
        
        rPat = fetch(c, sprintf(['SELECT D.Patologia, COUNT(*) as Casi FROM Diagnosi D ' ...
                                 'JOIN Eventi_Nascita E ON D.ID_Parto = E.ID_Parto ' ...
                                 'JOIN Pazienti P ON E.ID_Paziente = P.ID_Paziente ' ...
                                 'WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d GROUP BY D.Patologia ORDER BY Casi DESC'], regionSQL, annoNum));
        close(c);
        
        lblRegNascite.Text = sprintf('Nascite nel %s: %d', selectedYear, myExtractScalar(r1) * localFattore);
        lblRegEta.Text = sprintf('Età Media Madri: %.1f anni', myExtractScalar(r2));
        lblRegCesarei.Text = sprintf('Tasso Tagli Cesarei: %.1f%%', myExtractScalar(r3));
        lblRegPrematuri.Text = sprintf('Tasso Nati Prematuri: %.1f%%', myExtractScalar(r4));
        
        if isempty(rPat)
            tblDiagnosi.Data = {'Nessuna Anomalia', 0};
        else
            [dLabels, dCounts] = mySplitData(rPat);
            dData = cell(length(dLabels), 2);
            for r = 1:length(dLabels)
                dData{r,1} = dLabels{r};
                dData{r,2} = dCounts(r) * localFattore;
            end
            tblDiagnosi.Data = dData;
        end
        
        % --- GRAFICO 1: TREND MENSILE LINEARE ---
        cla(axRegTrendMensile);
        nomiMesi = {'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'};
        valoriMesi = zeros(1, 12);
        if ~isempty(rMesi)
            [mId, mCounts] = mySplitData(rMesi);
            for k = 1:length(mId)
                idx = mId(k);
                if iscell(idx); idx = idx{1}; end
                if ischar(idx) || isstring(idx); idx = str2double(idx); end
                if idx >= 1 && idx <= 12
                    valoriMesi(idx) = mCounts(k) * localFattore;
                end
            end
        end
        plot(axRegTrendMensile, 1:12, valoriMesi, '-', 'LineWidth', 2.5, 'Color', [0.30, 0.75, 1.0], ...
             'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', [1 1 1]);
        axRegTrendMensile.XTick = 1:12;
        axRegTrendMensile.XTickLabel = nomiMesi;
        title(axRegTrendMensile, sprintf('Nascite Mensili - %s (%s)', selectedRegion, selectedYear));
        
        % --- GRAFICO 2: SPLIT GENERE CON LEGEND COMPATIBILE ---
        cla(axRegSesso);
        if ~isempty(rSesso)
            [sessiLabels, sessiCounts] = mySplitData(rSesso);
            
            pObj = pie(axRegSesso, sessiCounts);
            
            for k = 1:2:length(pObj)
                labelIdx = (k+1)/2;
                nomeGenere = sessiLabels{labelIdx};
                
                if strcmp(nomeGenere, 'Maschio')
                    pObj(k).FaceColor = [0.12, 0.45, 0.84]; 
                else
                    pObj(k).FaceColor = [0.95, 0.42, 0.62]; 
                end
                
                pObj(k+1).Color = [1 1 1]; 
                pObj(k+1).FontSize = 11;
                pObj(k+1).FontWeight = 'bold';
                pObj(k+1).BackgroundColor = 'none';
            end
            
            % CORRETTO: Proprietà 'Color' al posto di 'BackgroundColor' per uiaxes legend
            legend(axRegSesso, string(sessiLabels), 'TextColor', [1 1 1], ...
                   'Color', [0.18, 0.18, 0.22], 'EdgeColor', 'none', ...
                   'Location', 'northeastoutside');
               
            title(axRegSesso, 'Ripartizione Maschi / Femmine');
        else
            title(axRegSesso, 'Nessun dato genere disponibile');
        end
        
        % --- GRAFICO 3: BARRE ORIZZONTALI PATOLOGIE ---
        cla(axRegPatologie);
        if ~isempty(rPat)
            [patLabels, patValues] = mySplitData(rPat);
            
            patLabelsStr = string(patLabels);
            valoriScalati = patValues * localFattore;
            
            barh(axRegPatologie, 1:length(patLabelsStr), valoriScalati, 'FaceColor', [1, 0.6, 0.2]);
            
            axRegPatologie.YTick = 1:length(patLabelsStr);
            axRegPatologie.YTickLabel = patLabelsStr;
            axRegPatologie.YLim = [0.5, length(patLabelsStr) + 0.5];
            
            title(axRegPatologie, 'Incidenza Malattie Neonatali (Casi Scalati)');
        else
            axRegPatologie.YTick = [];
            axRegPatologie.YTickLabel = {};
            title(axRegPatologie, 'Nessuna patologia rilevata');
        end
    end

    %% ====================================================================
    %% 5. FUNZIONI AUSILIARIE RINOMINATE E POSIZIONATE IN SICUREZZA
    %% ====================================================================
    function configDarkAxes(axObj, titolo)
        axObj.BackgroundColor = [0.15, 0.15, 0.17];
        axObj.XColor = [0.95 0.95 0.95];
        axObj.YColor = [0.95 0.95 0.95];
        axObj.Title.Color = [1 1 1];
        axObj.Title.String = titolo;
        grid(axObj, 'on');
        axObj.XGrid = 'on'; axObj.YGrid = 'on';
        axObj.GridColor = [0.3 0.3 0.3];
    end

    function val = myExtractScalar(inputData)
        if istable(inputData)
            arr = table2array(inputData);
            if isempty(arr); val = 0; else; val = arr(1,1); end
        elseif iscell(inputData)
            if isempty(inputData); val = 0; else; val = inputData{1,1}; end
        else
            if isempty(inputData); val = 0; else; val = inputData(1,1); end
        end
        if isempty(val) || isnan(val); val = 0; end
    end

    function [names, counts] = mySplitData(inputData)
        if istable(inputData)
            namesRaw = table2cell(inputData(:,1));
            countsRaw = table2array(inputData(:,2));
        else
            namesRaw = inputData(:,1);
            countsRaw = inputData(:,2);
        end
        if iscell(countsRaw)
            counts = cell2mat(countsRaw);
        else
            counts = countsRaw;
        end
        if isnumeric(namesRaw)
            names = namesRaw;
        else
            names = cellstr(string(namesRaw));
        end
    end
end