% GENERA DATASET MASSIVO (10.000 record) - CORRETTO
numRecord = 10000;
rng(1); % Per riproducibilità

% Definizioni
regioni = {'Lombardia', 'Lazio', 'Campania', 'Veneto', 'Emilia-Romagna', 'Piemonte', 'Toscana', 'Sicilia', 'Puglia', 'Liguria', 'Marche', 'Abruzzo', 'Friuli-Venezia Giulia', 'Trentino-Alto Adige', 'Umbria', 'Basilicata', 'Molise', 'Valle d''Aosta', 'Sardegna', 'Calabria'};
cittadinanze = {'Italiana', 'Italiana', 'Italiana', 'Italiana', 'Europea', 'Extra-UE'};
tipiParto = {'Naturale', 'Naturale', 'Cesareo'};
opzioniSesso = {'Maschio', 'Femmina'};

% Tabelle temporanee
pazienti = table((1:numRecord)', repmat(regioni', ceil(numRecord/20), 1), ...
    randi([18, 45], numRecord, 1), cellstr(cittadinanze(randi(length(cittadinanze), numRecord, 1)))', ...
    'VariableNames', {'ID_Paziente', 'Regione', 'Eta_Madre', 'Cittadinanza'});
pazienti = pazienti(1:numRecord, :);

eventi = table((1:numRecord)', (1:numRecord)', zeros(numRecord,1), zeros(numRecord,1), ...
    cell(numRecord,1), zeros(numRecord,1), cell(numRecord,1), zeros(numRecord,1), zeros(numRecord,1), cell(numRecord,1), ...
    'VariableNames', {'ID_Parto', 'ID_Paziente', 'Peso', 'Settimane_Gestazione', 'Tipo_Parto', 'Apgar', 'Data_Parto', 'Anno_Parto', 'Mese_Parto', 'Sesso'});

% Popolamento logico
for i = 1:numRecord
    % Logica prematurità (7% dei casi)
    if rand() < 0.07
        eventi.Settimane_Gestazione(i) = randi([28, 36]);
        eventi.Peso(i) = randi([1200, 2400]);
        eventi.Apgar(i) = randi([4, 8]);
    else
        eventi.Settimane_Gestazione(i) = randi([37, 41]);
        eventi.Peso(i) = randi([2800, 4000]);
        eventi.Apgar(i) = randi([8, 10]);
    end
    
    eventi.Tipo_Parto{i} = tipiParto{randi(3)};
    eventi.Sesso{i} = opzioniSesso{randi(2)}; % Corretto l'accesso all'indice
    
    anno = randi([2021, 2026]);
    mese = randi([1, 12]);
    giorno = randi([1, 28]);
    
    eventi.Anno_Parto(i) = anno;
    eventi.Mese_Parto(i) = mese;
    eventi.Data_Parto{i} = sprintf('%04d-%02d-%02d', anno, mese, giorno);
end

% Esportazione CSV
writetable(pazienti, 'pazienti.csv');
writetable(eventi, 'eventi_nascita.csv');

% Generazione Diagnosi (Solo per chi ha complicazioni)
idxComplicazioni = find(eventi.Settimane_Gestazione < 37 | rand(numRecord,1) < 0.05);
diagnosi = cell(0, 3);

for i = 1:length(idxComplicazioni)
    idParto = idxComplicazioni(i);
    diag = {'Ittero Neonatale', 'Distress Respiratorio', 'Prematurità Moderata', 'Deficit Crescita'};
    nDiag = randi([1, 2]); % Numero di diagnosi per parto
    
    for k = 1:nDiag
        nuovoId = size(diagnosi, 1) + 1;
        diagnosi(nuovoId, :) = {nuovoId, idParto, diag{randi(4)}};
    end
end

diagnosiTable = cell2table(diagnosi, 'VariableNames', {'ID_Diagnosi', 'ID_Parto', 'Patologia'});
writetable(diagnosiTable, 'diagnosi.csv');

disp('Database generato con successo: 10.000 record reali pronti in formato CSV.');