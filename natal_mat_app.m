function natal_mat_app()
    % NATAL-MAT - Dashboard Clinica Nazionale - PERCENTUALI TORTA CITTADINANZA
    
    %% ====================================================================
    %% 1. INIZIALIZZAZIONE E SICUREZZA FILE
    %% ====================================================================
    dbFile = 'natal_mat.db';
    fattoreScala = 1; 
    
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
    
    if ~exist('pazienti.csv', 'file') || ~exist('eventi_nascita.csv', 'file') || ~exist('diagnosi.csv', 'file')
        error('I file CSV non sono stati trovati! Esegui prima "generofogli.m" nella Command Window per creali.');
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
    %% 2. IMPORTAZIONE DATI MASSIVI DA CSV
    %% ====================================================================
    fprintf('Importazione file CSV in corso (10.000 record)... ');
    
    opts = detectImportOptions('pazienti.csv');
    opts.VariableTypes{2} = 'char'; 
    opts.VariableTypes{4} = 'char'; 
    tPazienti = readtable('pazienti.csv', opts);
    
    optsEv = detectImportOptions('eventi_nascita.csv');
    optsEv.VariableTypes{5} = 'char'; 
    optsEv.VariableTypes{7} = 'char'; 
    optsEv.VariableTypes{10} = 'char'; 
    tEventi = readtable('eventi_nascita.csv', optsEv);
    
    optsDiag = detectImportOptions('diagnosi.csv');
    optsDiag.VariableTypes{3} = 'char'; 
    tDiagnosi = readtable('diagnosi.csv', optsDiag);
    
    tPazienti.Regione = strrep(tPazienti.Regione, '''', '''''');
    
    sqlwrite(conn, 'Pazienti', tPazienti);
    sqlwrite(conn, 'Eventi_Nascita', tEventi);
    sqlwrite(conn, 'Diagnosi', tDiagnosi);
    
    close(conn);
    fprintf('Completata con successo!\n');

    %% ====================================================================
    %% 3. INTERFACCIA GRAFICA AD ALTO CONTRASTO (DARK MODE)
    %% ====================================================================
    fig = uifigure('Name', 'NATAL-MAT - Dashboard Clinica Nazionale', 'Position', [50, 50, 1250, 780]);
    fig.Color = [0.12, 0.12, 0.14]; 
    
    tabGroup = uitabgroup(fig, 'Position', [10, 10, 1230, 760]);
    tab1 = uitab(tabGroup, 'Title', 'Dashboard Nazionale');
    tab2 = uitab(tabGroup, 'Title', 'Dettaglio e Trend Temporali Regionali');
    
    listaRegioni = cellstr(unique(tPazienti.Regione));
    listaAnni = cellstr(string(unique(tEventi.Anno_Parto)));
    
    % --- SCHEDA 1: DASHBOARD NAZIONALE ---
    uilabel(tab1, 'Position', [20, 650, 180, 30], 'Text', 'Seleziona Anno Analisi:', 'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    ddAnnoNaz = uidropdown(tab1, 'Position', [200, 655, 100, 25], 'Items', listaAnni);
    
    pnlKPI = uipanel(tab1, 'Title', 'KPI NAZIONALI', 'Position', [20, 20, 280, 610], ...
                     'BackgroundColor', [0.18, 0.18, 0.22], 'FontWeight', 'bold', 'ForegroundColor', [1 1 1]);
    
    uilabel(pnlKPI, 'Position', [20, 520, 240, 20], 'Text', 'Nascite Totali:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    valNazNascite = uilabel(pnlKPI, 'Position', [20, 485, 240, 35], 'Text', '', 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [0.30, 0.75, 1.0]);
    
    uilabel(pnlKPI, 'Position', [20, 390, 240, 20], 'Text', 'Età Media Madre:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    valNazEta = uilabel(pnlKPI, 'Position', [20, 355, 240, 35], 'Text', '', 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [1, 1, 1]);
    
    uilabel(pnlKPI, 'Position', [20, 260, 240, 20], 'Text', 'Tasso Tagli Cesarei:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    valNazCes = uilabel(pnlKPI, 'Position', [20, 225, 240, 35], 'Text', '', 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [1, 0.4, 0.4]);
    
    uilabel(pnlKPI, 'Position', [20, 130, 240, 20], 'Text', 'Tasso Nati Prematuri:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
    valNazPrem = uilabel(pnlKPI, 'Position', [20, 95, 240, 35], 'Text', '', 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', [1, 0.75, 0.2]);
    
    axNasciteReg = uiaxes(tab1, 'Position', [330, 335, 850, 290]);
    axCittadinanza = uiaxes(tab1, 'Position', [330, 15, 850, 290]);
    
    configDarkAxes(axNasciteReg, 'Distribuzione Nazionale Nascite');
    configDarkAxes(axCittadinanza, 'Ripartizione Cittadinanza');
    
    ddAnnoNaz.ValueChangedFcn = @(dd, event) updateNationalStats(ddAnnoNaz.Value);

    % --- SCHEDA 2: DETTAGLIO REGIONALE + FILTRI ---
    uilabel(tab2, 'Position', [20, 620, 120, 22], 'Text', 'Regione:', 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    ddRegione = uidropdown(tab2, 'Position', [90, 620, 160, 22], 'Items', listaRegioni);
    
    uilabel(tab2, 'Position', [280, 620, 60, 22], 'Text', 'Anno:', 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    ddAnno = uidropdown(tab2, 'Position', [330, 620, 90, 22], 'Items', listaAnni);
    
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
    
    configDarkAxes(axRegTrendMensile, 'Andamento Mensile');
    configDarkAxes(axRegSesso, 'Ripartizione Genere');
    configDarkAxes(axRegPatologie, 'Frequenza Patologie Neonatali');
    
    annoIniziale = listaAnni{1};
    regioneIniziale = listaRegioni{1};
    updateNationalStats(annoIniziale);
    updateRegionalStats(regioneIniziale, annoIniziale);

    %% ====================================================================
    %% 4. CALLBACK SCHEDA 1: AGGIORNAMENTO NAZIONALE
    %% ====================================================================
    function updateNationalStats(selectedYear)
        localDbFile = 'natal_mat.db';
        c = sqlite(localDbFile);
        annoNum = str2double(selectedYear);
        
        nTot = myExtractScalar(fetch(c, sprintf('SELECT COUNT(*) FROM Eventi_Nascita WHERE Anno_Parto = %d', annoNum)));
        avgEta = myExtractScalar(fetch(c, sprintf('SELECT AVG(P.Eta_Madre) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE E.Anno_Parto = %d', annoNum)));
        percCes = myExtractScalar(fetch(c, sprintf('SELECT (COUNT(*)*100.0)/%d FROM Eventi_Nascita WHERE Anno_Parto = %d AND Tipo_Parto = ''Cesareo''', nTot, annoNum)));
        percPrem = myExtractScalar(fetch(c, sprintf('SELECT (COUNT(*)*100.0)/%d FROM Eventi_Nascita WHERE Anno_Parto = %d AND Settimane_Gestazione < 37', nTot, annoNum)));
        
        valNazNascite.Text = num2str(nTot * fattoreScala);
        valNazEta.Text = sprintf('%.1f anni', avgEta);
        valNazCes.Text = sprintf('%.1f%%', percCes);
        valNazPrem.Text = sprintf('%.1f%%', percPrem);
        
        % Grafico Barre Regioni
        cla(axNasciteReg);
        rData = fetch(c, sprintf('SELECT P.Regione, COUNT(*) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE E.Anno_Parto = %d GROUP BY P.Regione', annoNum));
        if ~isempty(rData)
            [regNames, regCounts] = mySplitData(rData);
            bar(axNasciteReg, categorical(string(regNames)), regCounts * fattoreScala, 'FaceColor', [0.15, 0.55, 0.85]);
        end
        title(axNasciteReg, sprintf('Distribuzione Regionale delle Nascite nell''anno %s', selectedYear));
        
        % Grafico Torta Cittadinanza con Etichette + Percentuali integrate
        cla(axCittadinanza);
        cData = fetch(c, sprintf('SELECT P.Cittadinanza, COUNT(*) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE E.Anno_Parto = %d GROUP BY P.Cittadinanza', annoNum));
        if ~isempty(cData)
            [citNames, citCounts] = mySplitData(cData);
            
            % Calcolo dinamico delle percentuali per popolare le stringhe di testo
            totaleFette = sum(citCounts);
            etichetteConPercentuale = cell(length(citNames), 1);
            for idxTorta = 1:length(citNames)
                pctVal = (citCounts(idxTorta) * 100) / totaleFette;
                etichetteConPercentuale{idxTorta} = sprintf('%s (%.1f%%)', citNames{idxTorta}, pctVal);
            end
            
            pPie = pie(axCittadinanza, citCounts, etichetteConPercentuale);
            
            % Uniforma il colore del testo a bianco per la Dark Mode
            for idxText = 2:2:length(pPie)
                pPie(idxText).Color = [1 1 1];
                pPie(idxText).FontSize = 10;
                pPie(idxText).FontWeight = 'bold';
            end
        end
        title(axCittadinanza, sprintf('Ripartizione Cittadinanza delle Madri nell''anno %s', selectedYear));
        
        close(c);
    end

    %% ====================================================================
    %% 5. CALLBACK SCHEDA 2: AGGIORNAMENTO REGIONALE
    %% ====================================================================
    function updateRegionalStats(selectedRegion, selectedYear)
        localDbFile = 'natal_mat.db';
        localFattore = 1;
        
        c = sqlite(localDbFile);
        regionSQL = strrep(selectedRegion, '''', '''''');
        annoNum = str2double(selectedYear);
        
        r1 = fetch(c, sprintf('SELECT COUNT(*) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d', regionSQL, annoNum));
        r2 = fetch(c, sprintf('SELECT AVG(P.Eta_Madre) FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente = E.ID_Paziente WHERE P.Regione = ''%s'' AND E.Anno_Parto = %d', regionSQL, annoNum));
        
        nLoc = myExtractScalar(r1);
        if nLoc > 0
            r3 = fetch(c, sprintf('SELECT (COUNT(*)*100.0)/%d FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente=E.ID_Paziente WHERE P.Regione=''%s'' AND E.Anno_Parto=%d AND E.Tipo_Parto=''Cesareo''', nLoc, regionSQL, annoNum));
            r4 = fetch(c, sprintf('SELECT (COUNT(*)*100.0)/%d FROM Pazienti P JOIN Eventi_Nascita E ON P.ID_Paziente=E.ID_Paziente WHERE P.Regione=''%s'' AND E.Anno_Parto=%d AND E.Settimane_Gestazione < 37', nLoc, regionSQL, annoNum));
            r3Val = myExtractScalar(r3); r4Val = myExtractScalar(r4);
        else
            r3Val = 0; r4Val = 0;
        end
                           
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
        
        lblRegNascite.Text = sprintf('Nascite nel %s: %d', selectedYear, nLoc * localFattore);
        lblRegEta.Text = sprintf('Età Media Madri: %.1f anni', myExtractScalar(r2));
        lblRegCesarei.Text = sprintf('Tasso Tagli Cesarei: %.1f%%', r3Val);
        lblRegPrematuri.Text = sprintf('Tasso Nati Prematuri: %.1f%%', r4Val);
        
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
        
        % --- GRAFICO 1: TREND MENSILE ---
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
        
        % --- GRAFICO 2: SPLIT GENERE ---
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
                pObj(k+1+1-1).FontSize = 11;
                pObj(k+1).FontWeight = 'bold';
                pObj(k+1).BackgroundColor = 'none';
            end
            legend(axRegSesso, string(sessiLabels), 'TextColor', [1 1 1], ...
                   'Color', [0.18, 0.18, 0.22], 'EdgeColor', 'none', 'Location', 'northeastoutside');
            title(axRegSesso, 'Ripartizione Maschi / Femmine');
        else
            title(axRegSesso, 'Nessun dato genere disponibile');
        end
        
        % --- GRAFICO 3: BARRE ORIZZONTALI PATOLOGIE ---
        cla(axRegPatologie);
        if ~isempty(rPat)
            [patLabels, patValues] = mySplitData(rPat);
            patLabelsStr = string(patLabels);
            barh(axRegPatologie, 1:length(patLabelsStr), patValues * localFattore, 'FaceColor', [1, 0.6, 0.2]);
            axRegPatologie.YTick = 1:length(patLabelsStr);
            axRegPatologie.YTickLabel = patLabelsStr;
            axRegPatologie.YLim = [0.5, length(patLabelsStr) + 0.5];
            title(axRegPatologie, 'Incidenza Malattie Neonatali (Casi Reali)');
        else
            axRegPatologie.YTick = []; axRegPatologie.YTickLabel = {};
            title(axRegPatologie, 'Nessuna patologia rilevata');
        end
    end

    %% ====================================================================
    %% 6. FUNZIONI AUSILIARIE
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