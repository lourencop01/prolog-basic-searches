% Numero: 95817 Nome: Lourenco Pacheco

% Para listas completas.
:- set_prolog_flag(answer_write_options,[max_depth(0)]).
% Ficheiros a importar.
:- ['dados.pl'], ['keywords.pl'].

% - - - - - - - - - - - - -
%  3.1 Qualidade dos dados |
% - - - - - - - - - - - - -

% eventosSemSalas/1:
%   - Procura todos os eventos na base de dados que estao sem sala.
%   - Devolve uma lista ordenada e sem repeticoes dos eventos encontrados.

eventosSemSalas(EventosSemSala) :-
    findall(Id, evento(Id, _, _, _, 'semSala'), Temp),
    sort(Temp, EventosSemSala).



% eventosSemSalasDiaSemana/2:
%   - Procura todos os eventos sem sala num determinado DiaDaSemana.
%   - Devolve uma lista ordenada e sem repeticoes dos eventos encontrados.

eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) :-
    findall(Id, (evento(Id, _, _, _, 'semSala'),
                 horario(Id, DiaDaSemana, _, _, _, _)), Temp),
    sort(Temp, EventosSemSala).



% eventosSemSalasPeriodo/2:
%   - Procura todos os eventos sem sala num determinado espaco de tempo.
%   - Devolve uma lista ordenada e sem repeticoes dos eventos encontrados.

eventosSemSalasPeriodo(ListaPeriodos, EventosSemSala) :-
    is_list(ListaPeriodos),
    inclui_semestrais(ListaPeriodos, NovaListaPeriodos),
    findall(Id, (evento(Id, _, _, _, 'semSala'),
                 horario(Id, _, _, _, _, Periodo),
                 member(Periodo, NovaListaPeriodos)), Temp),
    sort(Temp, EventosSemSala), !.



% - - - - - - - - - - - - -
%   3.2 Pesquisas Simples  |
% - - - - - - - - - - - - -

% organizaEventos/3:
%   - Confirma quais eventos em ListaEventos se encontram no Periodo e
%     devolve-os na lista EventosNoPeriodo.

organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) :-
    inclui_semestrais([Periodo], ListaPeriodos),
    organizaEventos_aux(ListaEventos, ListaPeriodos, EventosDesordenados),
    sort(EventosDesordenados, EventosNoPeriodo), !.

organizaEventos_aux([], _, []).
organizaEventos_aux([H|T], Periodos, [H|Prev]) :-
    member(Periodo, Periodos),
    evento(H, _, _, _, _),
    horario(H, _, _, _, _, Periodo),
    organizaEventos_aux(T, Periodos, Prev), !.
organizaEventos_aux([_|T], Periodos, EventosNoPeriodo) :-
    organizaEventos_aux(T, Periodos, EventosNoPeriodo), !.



% eventosMenoresQue/2:
%   - Devolve uma lista (ListaEventosMenoresQue) que contem todos os eventos
%     com duracao menor ou igual a Duracao.

eventosMenoresQue(Duracao, ListaEventosMenoresQue) :-
    findall(Id, (evento(Id, _, _, _, _),
                 horario(Id, _, _, _, Dur, _),
                 Dur =< Duracao), Temp),
    sort(Temp, ListaEventosMenoresQue).



% eventosMenoresQueBool/2:
%   - Devolve true se o evento com Id tiver duracao igual ou menor a Duracao.
%     Devolve false, caso contrario.

eventosMenoresQueBool(ID, Duracao) :-
    evento(ID, _, _, _, _),
    horario(ID, _, _, _, Dur, _),
    Dur =< Duracao.



% procuraDisciplinas/2:
%   - Devolve uma lista ordenada alfabeticamente de todas as disciplinas
%     pertencentes ao Curso.

procuraDisciplinas(Curso, ListaDisciplinas) :-
    findall(Disciplina, (turno(Id, Curso, _, _),
                         evento(Id, Disciplina, _, _, _)), Temp),
    sort(Temp, ListaDisciplinas).



% organizaDisciplinas/3:
%   - Devolve uma lista com duas listas, a primeira com as disciplinas da
%     ListaDisciplinas lecionadas no primeiro semestre e a segunda com as
%     disciplinas da ListaDisciplinas lecionadas no segundo semestre.

organizaDisciplinas(ListaDisciplinas, Curso, Semestres) :-
    procuraDisciplinas(Curso, ListaDisciplinasCurso),
    subset(ListaDisciplinas, ListaDisciplinasCurso),    % True se as disciplinas fornecidas pertecem ao Curso.
    organizaDisciplinas_aux(ListaDisciplinas, Curso, Semestre1, Semestre2),
    sort(Semestre1, SortedSem1),
    sort(Semestre2, SortedSem2),
    Semestres = [SortedSem1, SortedSem2], !.

organizaDisciplinas_aux([], _, [], []).
organizaDisciplinas_aux([H|T], Curso, [H|Prev], Semestre2) :-
    member(Periodo, ['p1', 'p2', 'p1_2']),
    evento(Id, H, _, _, _),
    turno(Id, Curso, _, _),
    horario(Id, _, _, _, _, Periodo),
    organizaDisciplinas_aux(T, Curso, Prev, Semestre2).
organizaDisciplinas_aux([H|T], Curso, Semestre1, [H|Prev]) :-
    member(Periodo, ['p3', 'p4', 'p3_4']),
    evento(Id, H, _, _, _),
    turno(Id, Curso, _, _),
    horario(Id, _, _, _, _, Periodo),
    organizaDisciplinas_aux(T, Curso, Semestre1, Prev).


% horasCurso/4:
%   - Devolve a soma (TotalHoras) de todas as duracoes de eventos lecionados
%     em Periodo para o Curso no Ano.

horasCurso(Periodo, Curso, Ano, TotalHoras) :-
    inclui_semestrais([Periodo], NovaListaPeriodos),
    findall(Id, (member(Periodos, NovaListaPeriodos),
                 evento(Id, _, _, _, _),
                 horario(Id, _, _, _, _, Periodos),
                 turno(Id, Curso, Ano, _)), Temp),
    sort(Temp, SortedTemp),
    findall(TempId, member(TempId, SortedTemp), IdList),
    horasCurso_aux(IdList, TotalHoras), !.

horasCurso_aux([], 0).
horasCurso_aux([H|T], TotalHoras) :-
    horario(H, _, _, _, Duracao, _),
    horasCurso_aux(T, Prev),
    TotalHoras is Duracao + Prev.




% evolucaoHorasCurso/5
%   - Devolve uma lista de tuplos na forma (Ano, Periodo, NumHoras), em que
%     NumHoras e o total de horas associadas ao curso Curso, no ano Ano e periodo
%     Periodo.

evolucaoHorasCurso(Curso, Evolucao) :-
    findall((Ano, Periodo, TotalHoras), (member(Ano, [1,2,3]),
                                         member(Periodo, [p1, p2, p3, p4]),
                                         horasCurso(Periodo, Curso, Ano,
                                                    TotalHoras)), UnsortedEvo),
    sort(UnsortedEvo, Evolucao).



% - - - - - - - - - - - - - - - - -
%  3.3 Ocupacoes criticas de salas |
% - - - - - - - - - - - - - - - - -



% ocupaSlot/5:
%   - Devolve a quantidade de tempo sobreposta entre HoraInicioDada e HoraFimDada
%     e HoraInicioEvento e HoraFimEvento, ou seja, a intersecao do intervalo de
%     tempo [HoraInicioDada, HoraFimDada] e [HoraInicioEvento, HoraFimEvento].

ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    ocupaSlot_aux(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas),
    Horas > 0.

ocupaSlot_aux(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    HoraInicioEvento >= HoraInicioDada,
    HoraFimEvento =< HoraFimDada,
    Horas is HoraFimEvento - HoraInicioEvento, !.
ocupaSlot_aux(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    HoraInicioEvento =< HoraInicioDada,
    HoraFimEvento >= HoraFimDada,
    Horas is HoraFimDada - HoraInicioDada, !.
ocupaSlot_aux(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    HoraInicioEvento =< HoraInicioDada,
    HoraFimEvento =< HoraFimDada,
    Horas is HoraFimEvento - HoraInicioDada, !.
ocupaSlot_aux(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    HoraInicioEvento >= HoraInicioDada,
    HoraFimEvento >= HoraFimDada,
    Horas is HoraFimDada - HoraInicioEvento, !.



% numHorasOcupadas/6:
%   - Devolve o numero de horas ocupadas nas salas do tipo TipoSala, no intervalo
%     de tempo definido entre HoraInicio e HoraFim, no dia da semana DiaSemana,
%     e no periodo Periodo.

numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras) :-
    salas(TipoSala, ListaSalas),
    inclui_semestrais([Periodo], ListaPeriodos),
    findall([HoraInicioEvento, HoraFimEvento], (member(Salas, ListaSalas),
                                                member(Periodos, ListaPeriodos),
                                                evento(Id, _, _, _, Salas),
                                                horario(Id, DiaSemana,
                                                        HoraInicioEvento,
                                                        HoraFimEvento, _,
                                                        Periodos)), ListaHoras),
    findall(Horas, (member([HoraInicioEvento, HoraFimEvento|_], ListaHoras),
                    ocupaSlot(HoraInicio, HoraFim, HoraInicioEvento,
                              HoraFimEvento, Horas
                             )), ListaHorasCertas),
    sumlist(ListaHorasCertas, SomaHoras), !.    % Faz a soma de todos os elementos da lista.



% ocupacaoMax/4:
%   - Devolve o numero Max de horas ocupadas em salas TipoSala entre HoraInicio
%     e HoraFim.

ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max) :-
    salas(TipoSala, ListaSalas),
    length(ListaSalas, NumeroDeSalas),
    Max is (HoraFim - HoraInicio) * NumeroDeSalas.


% percentagem/3:
%   - Devolve a percentagem de SomaHoras em relacao a Max.

percentagem(SomaHoras, Max, Percentagem) :-
    Percentagem is (SomaHoras/Max)*100.



% ocupacaoCritica/4:
%   - Devolve os casos criticos (percentagem de horas ocupadas acima de
%     threshold) sob a forma de uma lista de casosCriticos(DiaDaSemana, TipoSala,
%     Percentagem).

ocupacaoCritica(HoraInicio, HoraFim, Threshold, Resultados) :-
    findall(SalaTipo, salas(SalaTipo, _), ListaTiposSalas),
    DiasDaSemana = [segunda-feira, terca-feira, quarta-feira, quinta-feira, sexta-feira],
    Periodos = [p1, p2, p3, p4],
    findall([DiaSemana, TipoSala, Percentagem], (member(TipoSala, ListaTiposSalas),
                                                 member(DiaSemana, DiasDaSemana),
                                                 member(Periodo, Periodos),
                                                 numHorasOcupadas(Periodo, TipoSala,
                                                                  DiaSemana, HoraInicio,
                                                                  HoraFim, SomaHoras),
                                                 ocupacaoMax(TipoSala, HoraInicio,
                                                             HoraFim, Max),
                                                 percentagem(SomaHoras, Max, Percentagem),
                                                 Percentagem > Threshold), Temp),
    maplist(ocupacaoCritica_aux, Temp, UnsortedResultados),
    sort(UnsortedResultados, Resultados).

ocupacaoCritica_aux(Tuplo, Resultado) :-
    [DiaSemana, TipoSala, Percentagem] = Tuplo,
    ceiling(Percentagem, Arredondamento),   % Arredonda as unidades o valor fornecido.
    Resultado = casosCriticos(DiaSemana, TipoSala, Arredondamento).



% - - - - - - - - - - - - - - - - - - - - - - - - - -
%  3.4 And now for something completely different... |
% - - - - - - - - - - - - - - - - - - - - - - - - - -


% ocupacaoMesa/3:
%   - Recebe uma lista de 8 pessoas (ListaPessoas), e uma lista de restricoes
%     (ListaRestricoes) e devolve uma solucao que satisfaca todas as condicoes
%     na ListaRestricoes.

:- dynamic mesa/1.


ocupacaoMesa(ListaPessoas, ListaRestricoes, OcupacaoMesa) :-
    is_list(ListaPessoas),
    length(ListaPessoas, 8),
    is_list(ListaRestricoes),
    findall([[X1, X2, X3], [X4, X5], [X6, X7, X8]],
            ocupacaoMesa_aux(ListaPessoas, ListaRestricoes,
                             [X1, X2, X3, X4, X5, X6, X7, X8]), Mesas),
    [OcupacaoMesa] = Mesas.

ocupacaoMesa_aux(ListaPessoas, ListaRestricoes, OcupacaoMesa) :-
    permutation(ListaPessoas, Possibilidade),   % Cria todas as possibilidades de arranjo da ListaPessoas.
    asserta(mesa(Possibilidade)),
    verificaRestricoes(ListaRestricoes, Possibilidade, OcupacaoMesa), !.

verificaRestricoes([], PossibilidadeCerta, PossibilidadeCerta) :- !.
verificaRestricoes([Restricao|Restantes], Possibilidade, OcupacaoMesa) :-
    call(Restricao),
    verificaRestricoes(Restantes, Possibilidade, OcupacaoMesa).

verificaRestricoes(_, Possibilidade, _) :-
    retract(mesa(Possibilidade)),
    fail.

cab1(NomePessoa) :-
    mesa([_, _, _, NomePessoa, _, _, _, _]).

cab2(NomePessoa) :-
    mesa([_, _, _, _, NomePessoa, _, _, _]).

honra(NomePessoa1, NomePessoa2) :-
    mesa([_, _, _, NomePessoa1, _, NomePessoa2, _, _]).

honra(NomePessoa1, NomePessoa2) :-
    mesa([_, _, NomePessoa2, _, NomePessoa1, _, _, _]).

lado(NomePessoa1, NomePessoa2) :-
    mesa([NomePessoa1, NomePessoa2, _, _, _, _, _, _]);
    mesa([_, NomePessoa1, NomePessoa2, _, _, _, _, _]);
    mesa([_, _, _, _, _, NomePessoa1, NomePessoa2, _]);
    mesa([_, _, _, _, _, _, NomePessoa1, NomePessoa2]);
    mesa([NomePessoa2, NomePessoa1, _, _, _, _, _, _]);
    mesa([_, NomePessoa2, NomePessoa1, _, _, _, _, _]);
    mesa([_, _, _, _, _, NomePessoa2, NomePessoa1, _]);
    mesa([_, _, _, _, _, _, NomePessoa2, NomePessoa1]).

naoLado(NomePessoa1, NomePessoa2) :-
    not(lado(NomePessoa1, NomePessoa2)).

frente(NomePessoa1, NomePessoa2) :-
    mesa([NomePessoa1, _, _, _, _, NomePessoa2, _, _]);
    mesa([NomePessoa2, _, _, _, _, NomePessoa1, _, _]);
    mesa([_, NomePessoa1, _, _, _, _, NomePessoa2, _]);
    mesa([_, NomePessoa2, _, _, _, _, NomePessoa1, _]);
    mesa([_, _, NomePessoa1, _, _, _, _, NomePessoa2]);
    mesa([_, _, NomePessoa2, _, _, _, _, NomePessoa1]).

naoFrente(NomePessoa1, NomePessoa2) :-
    not(frente(NomePessoa1, NomePessoa2)).





% - - - - - - - - - - - -
%  Predicados auxiliares |
% - - - - - - - - - - - -

% inclui_semestrais/2:
%   - recebe uma lista de periodos e adiciona a lista os semestres correspondentes.

inclui_semestrais(ListaPeriodos, NovaListaPeriodos) :-
    is_list(ListaPeriodos),
    inclui_aux(ListaPeriodos, Temp),
    sort(Temp, NovaListaPeriodos).

inclui_aux([], []).
inclui_aux([H|T], [H,'p1_2'|Prev]) :-
    (H == 'p1'; H == 'p2'),
    inclui_aux(T, Prev).
inclui_aux([H|T], [H,'p3_4'|Prev]) :-
    (H == 'p3'; H == 'p4'),
    inclui_aux(T, Prev).
inclui_aux([H|T], [H|Prev]) :-
    (H == 'p1_2'; H == 'p3_4'),
    inclui_aux(T, Prev).