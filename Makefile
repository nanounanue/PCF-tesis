# -*- Mode: Makefile -*-

# Lista de Documentos principales 
TEX_PRINCIPAL := $(shell egrep -l '^\\begin\{document\}' *.tex)
# Lista de Documentos a  los cuales hay que obtener la bibliografia
ARCHIVOS_BIBTEX := $(shell egrep -l '\\PCFbibliografiacapitulo' *.tex)
# Lista todos los documentos tex
ARCHIVOS_TEX := $(shell ls *.tex)


export TEXINPUTS:=.:$(HOME)/latex/sty:$(TEXINPUTS)
export BSTINPUTS:=.:$(HOME)/latex/sty:$(BSTINPUTS)
export BIBINPUTS:=.:$(HOME)/latex/bibtex:$(BIBINPUTS)

.SUFFIXES: .tex .dvi .pdf .ps

#
#
# Modificado: Adolfo De Unanue (nano)
# http://nano.dialetheia.net
#
fileinfo	:= LaTeX Makefile
author		:= Adolfo De Unanue T
# Author: Scott A. Kuhl        (SAK)
# http://www.cs.utah.edu/~skuhl/


# Maximo numero de pasadas de LaTeX si existen referencias sin definir.
# Nota: MAX_PASADAS no toma en cuenta la primera pasada de LaTeX
MAX_PASADAS=5
FECHA=`date +%d%m%y`


# Directorios
# Imagenes
ifndef DIR_FIGURAS
	DIR_FIGURAS=imagenes
endif

ifndef DIR_TESIS
	DIR_TESIS=.
endif


# Programas
LATEX=latex
LATEX_ARGS=-file-line-error-style -interaction=nonstopmode
PDFLATEX=pdflatex
EPSTOPDF=epstopdf
BIBTEX=bibtex
PS2PDF=ps2pdf
MAKEINDEX=makeindex
DVIPS=dvips
DVIPS_ARGS=-t letter -f -Ppdf -G0 
TAR=tar
TAR_ARGS=-czf



# Visualizadores
ifndef TEXEDITOR
	TEXEDITOR=emacs
endif

ifndef DVIVIEWER
	DVIVIEWER=xdvi
endif

ifndef PSVIEWER
	PSVIEWER=evince
endif

ifndef PDFVIEWER
	PDFVIEWER=xpdf
endif

# RegEx para los avisos de pcf_tesis
PCF_TESIS_REFEX = "Class pcf_tesis Warning:"

# RegEx para los warnings en la pantalla 
LATEX_WARNING_REGEX=-e '\(LaTeX Warning\)\|\(Overfull\)\|\(Underfull\)'

# RegEx para citas no definidas
LATEX_UNDEF_CITE_REGEX='Citation.*undefined'

# RegEx para cualquier tipo de referencia no definida y para etiquetas (labels) que han cambiado
LATEX_RERUN_REGEX=-e '\(Citation.*undefined\)\|\(LaTeX Warning: There were undefined references\)\|\(LaTeX Warning: Label(s) may have changed\)\|\(Package natbib Warning: There were undefined citations.\)\|\(Package natbib Warning: Citation(s) may have changed.\)'

# RegEx pra usar en el indice
LATEX_IDX_REGEX="Writing index file.*idx"

# RegEx para usar con las nomenclaturas
LATEX_NOMENCL_REGEX="Writing nomenclature file.*nlo"

############################################################
##
##               ¡ PELIGRO !
##          Si no sabe lo que hace, 
##     no mueva nada debajo de estas lineas
##
############################################################

# Remueve la extension .tex
TEX_PRINCIPAL:=$(TEX_PRINCIPAL:.tex=)

DVI_PRINCIPAL:=$(addsuffix .dvi, ${TEX_PRINCIPAL})
PS_PRINCIPAL:=$(addsuffix .ps, ${TEX_PRINCIPAL})
PDF_PRINCIPAL:=$(addsuffix .pdf, ${TEX_PRINCIPAL})

ARCHIVOS_BIBTEX:=$(ARCHIVOS_BIBTEX:.tex=)
ARCHIVOS_TEX:=$(ARCHIVOS_TEX:.tex=)

# Este makefile esconde la salida de latex, bibtex, dvips.
# Su salida es enviada a archivos en un subdirectorio tmp para 
# ser inspeccionados luego.
LATEX_OUTPUT=tmp/${basename ${@}}-latex.txt
BIBTEX_OUTPUT=tmp/${basename ${@}}-bibtex.txt
DVIPS_OUTPUT=tmp/${basename ${@}}-dvips.txt
INDEX_OUTPUT=tmp/${basename ${@}}-index.txt
NOMENCL_OUTPUT=tmp/${basename ${@}}-nomencl.txt

# Este makefile REQUIERE bash. Probablemente no funcione con otros shells.
SHELL=/bin/bash


# Targets para crear PDFs, PSs, DVIs para todos los TEX_PRINCIPAL
.PHONY: all install clean limpiar ayuda help info ver ver-pdf ver-ps tar 

dvi: $(DVI_PRINCIPAL)
pdf: $(PDF_PRINCIPAL)
ps: $(PS_PRINCIPAL)


all : ps dvi

#
# Dependencias
#

$(PS_PRINCIPAL) : $(DVI_PRINCIPAL)
$(DVI_PRINCIPAL) : $(addsuffix .tex, ${TEX_PRINCIPAL}) 
$(PDF_PRINCIPAL) : $(addsuffix .tex, ${TEX_PRINCIPAL}) 

#
# Reglas generales
#

.tex.dvi :
	@mkdir -p tmp
## Ejecutamos latex una vez
	@echo "Latex [0] $*";
	@$(LATEX) $(LATEX_ARGS) $*  > ${LATEX_OUTPUT};

## Si hay citas sin definir ejecuta bibtex
	@-BAD_REFS=`grep ${LATEX_UNDEF_CITE_REGEX} ${LATEX_OUTPUT} | wc -l`; \
	if [[ $$BAD_REFS > 0 ]]; then \
	echo "BibTeX $*"; \
	${BIBTEX}  $* > ${BIBTEX_OUTPUT} 2>&1; \
	fi;

	@echo "LaTeX [1] $*";
	@$(LATEX) $(LATEX_ARGS) $* > ${LATEX_OUTPUT};

	@INDEX=`grep ${LATEX_IDX_REGEX} ${LATEX_OUTPUT} | wc -l`; \
	if [[ $$INDEX > 0 ]]; then \
	echo "Glosario: makeindex $*"; \
	${MAKEINDEX}  $* > ${INDEX_OUTPUT} 2>&1; \
	fi;

	@NOMENCLINDEX=`grep ${LATEX_NOMENCL_REGEX} ${LATEX_OUTPUT} | wc -l`; \
	if [[ $$NOMENCLINDEX > 0 ]]; then \
	echo "Simbolos: makeindex ${@:.dvi=.nlo}"; \
	${MAKEINDEX} ${@:.dvi=.nlo} -s nomencl.ist -o ${@:.dvi=.nls} > ${NOMENCL_OUTPUT} 2>&1; \
	fi;

	@echo "LaTeX [2] $*";
	@$(LATEX) $(LATEX_ARGS) $* > ${LATEX_OUTPUT};


	@if [[ "$(ARCHIVOS_BIBTEX)" ]]; then \
		echo "Hay capitulos con bibliografia..." ; \
		for file in bogus $(ARCHIVOS_BIBTEX) ; do \
			if test "$$file" != "bogus"; then  \
				echo "Procesando $$file..." ; \
				if [ -e $$file.aux ]; then \
					echo "BibTeX en capiulos: $$file"; \
					$(BIBTEX) $$file >> ${BIBTEX_OUTPUT}; \
				fi; \
			fi; \
		done ; \
	fi;

	@echo "LaTeX [3] $*";
	@$(LATEX) $(LATEX_ARGS) $* > ${LATEX_OUTPUT};

	@echo "LaTeX [4] $*";
	@$(LATEX) $(LATEX_ARGS) $* > ${LATEX_OUTPUT};

	@echo "LaTeX [5] $*";
	@$(LATEX) $(LATEX_ARGS) $* > ${LATEX_OUTPUT};


.tex.pdf:
## Eliminamos los pdf anteriores
	@-rm ./${DIR_FIGURAS}/*.pdf

## Convertimos las imagenes a pdf
	@for file in `ls ${DIR_FIGURAS}`; do \
		echo "Convirtiendo imagen $$file a PDF..."; \
		$(EPSTOPDF) ./${DIR_FIGURAS}/$$file; \
	done ;

	@mkdir -p tmp
## Ejecutamos latex una vez
	@echo "$@  $* $<"
	@echo "PDFLatex [0] $*";
	@$(PDFLATEX)  $*  > ${LATEX_OUTPUT};

## Si hay citas sin definir ejecuta bibtex
	@-BAD_REFS=`grep ${LATEX_UNDEF_CITE_REGEX} ${LATEX_OUTPUT} | wc -l`; \
	if [[ $$BAD_REFS > 0 ]]; then \
	echo "BibTeX $*"; \
	${BIBTEX}  $* > ${BIBTEX_OUTPUT} 2>&1; \
	fi;

	@echo "PDFLaTeX [1] $*";
	@$(PDFLATEX)  $* > ${LATEX_OUTPUT};

	@INDEX=`grep ${LATEX_IDX_REGEX} ${LATEX_OUTPUT} | wc -l`; \
	if [[ $$INDEX > 0 ]]; then \
	echo "Glosario: makeindex $*"; \
	${MAKEINDEX}  $* > ${INDEX_OUTPUT} 2>&1; \
	fi;

	@NOMENCLINDEX=`grep ${LATEX_NOMENCL_REGEX} ${LATEX_OUTPUT} | wc -l`; \
	if [[ $$NOMENCLINDEX > 0 ]]; then \
	echo "Simbolos: makeindex ${@:.dvi=.nlo}"; \
	${MAKEINDEX} ${@:.dvi=.nlo} -s nomencl.ist -o ${@:.dvi=.nls} > ${NOMENCL_OUTPUT} 2>&1; \
	fi;

	@echo "PDFLaTeX [2] $*";
	@$(PDFLATEX)  $* > ${LATEX_OUTPUT};


	@if [[ "$(ARCHIVOS_BIBTEX)" ]]; then \
		echo "Hay capitulos con bibliografia..." ; \
		for file in bogus $(ARCHIVOS_BIBTEX) ; do \
			if test "$$file" != "bogus"; then  \
				echo "Procesando $$file..." ; \
				if [ -e $$file.aux ]; then \
					echo "BibTeX en capiulos: $$file"; \
					$(BIBTEX) $$file >> ${BIBTEX_OUTPUT}; \
				fi; \
			fi; \
		done ; \
	fi;

	@echo "PDFLaTeX [3] $*";
	@$(PDFLATEX)  $* > ${LATEX_OUTPUT};

	@echo "PDFLaTeX [4] $*";
	@$(PDFLATEX)  $* > ${LATEX_OUTPUT};

	@echo "PDFLaTeX [5] $*";
	@$(PDFLATEX)  $* > ${LATEX_OUTPUT};


.dvi.ps:
	@mkdir -p tmp
	@echo "dvips    ${@:.p=.dvi} ${@}"
	$(DVIPS) $(DVIPS_ARGS) -o $*.ps $* > ${DVIPS_OUTPUT}

tar : 
	@echo "El archivo comprimido se colocará en ${HOME}, con el nombre tesis-${FECHA}.tar.gz"
	cp  "${HOME}/texmf/bibtex/bst/flexbib/flexbib.bst" .
	cp  "${HOME}/texmf/tex/latex/flexbib/spanishbst.tex" .
	cp  "${HOME}/texmf/tex/latex/flexbib/flexbib.sty" .
	cp  "${HOME}/texmf/tex/latex/acronym/acronym.sty" .
	cp  "${HOME}/texmf/tex/latex/changes/changes.sty" .
	cp  "${HOME}/texmf/tex/latex/todonotes/todonotes.sty" .
	cp  "${HOME}/texmf/tex/latex/base/pcftesis.cls" .
	@$(TAR) $(TAR_ARGS) "${HOME}/tesis-${FECHA}".tar.gz *.tex *.cls *.sty *.bst "${DIR_FIGURAS}" figuras 
	rm  -rf ./flexbib.bst 
	rm  -rf ./spanishbst.tex 
	rm  -rf ./flexbib.sty 
	rm  -rf ./changes.sty
	rm  -rf ./todonostes.sty
	rm  -rf ./pcftesis.cls
	rm  -rf ./acronym.sty

borrar :
	@rm -fv \
	$(addsuffix .aux,${ARCHIVOS_TEX}) \
	$(addsuffix .log,${ARCHIVOS_TEX}) \
	$(addsuffix .bbl,${ARCHIVOS_TEX}) \
	$(addsuffix .blg,${ARCHIVOS_TEX}) \
	$(addsuffix .toc,${ARCHIVOS_TEX}) \
	$(addsuffix .ilg,${ARCHIVOS_TEX}) \
	$(addsuffix .lof,${ARCHIVOS_TEX}) \
	$(addsuffix .lot,${ARCHIVOS_TEX}) \
	$(addsuffix .idx,${ARCHIVOS_TEX}) \
	$(addsuffix .ind,${ARCHIVOS_TEX}) \
	$(addsuffix .out,${ARCHIVOS_TEX}) \
	$(addsuffix .nlo,${ARCHIVOS_TEX}) \
	$(addsuffix .lox,${ARCHIVOS_TEX}) \
	$(addsuffix .lol,${ARCHIVOS_TEX}) \
	$(addsuffix .loc,${ARCHIVOS_TEX}) \
	$(addsuffix .tdo,${ARCHIVOS_TEX}) \
	$(addsuffix .nls,${ARCHIVOS_TEX})

	@rm -rfv tmp *~ auto

	@rm -fv \
	$(addsuffix .pdf,${TEX_PRINCIPAL}) \
	$(addsuffix .ps ,${TEX_PRINCIPAL}) \
	$(addsuffix .dvi,${TEX_PRINCIPAL})

clean : borrar

help : ayuda

install:
	$(LATEX) pcftesis.ins
	$(LATEX) pcftesis.dtx
	$(LATEX) pcftesis.dtx
	@echo "Creando árbol local de TeX"
	mkdir -p  "${HOME}/texmf/tex/latex/base"
	mkdir -p  "${HOME}/texmf/tex/latex/changes"
	mkdir -p  "${HOME}/texmf/tex/latex/todonotes"
	mkdir -p  "${HOME}/texmf/tex/latex/acronym"
	mkdir -p  "${HOME}/texmf/doc/pcftesis"
	mkdir -p  "${HOME}/texmf/bibtex/bst"	
# sudo cp -R texmf-flexbib/bibtex /usr/share/texmf-texlive/
# sudo cp -R texmf-flexbib/tex /usr/share/texmf-texlive/
# sudo cp -R texmf-flexbib/doc/flexbib /usr/share/doc/texlive-doc/bibtex
#	rm -rf  texmf-flexbib
#	sudo texhash
	@echo "Copiando los archivos necesarios al árbol local de TeX"
	cp -R texmf-flexbib/* "${HOME}/texmf/"
	cp pcftesis.cls   "${HOME}/texmf/tex/latex/base/"
	cp pcftesis.dvi   "${HOME}/texmf/doc/pcftesis/"
	cp changes.sty    "${HOME}/texmf/tex/latex/changes/"
	cp todonotes.sty  "${HOME}/texmf/tex/latex/todonotes/"
	cp acronym.sty    "${HOME}/texmf/tex/latex/acronym/"
	@if [ "${DIR_TESIS}" != "." ]; then \
		echo "Creando el directorio de imagenes";\
		mkdir -p "${DIR_TESIS}/imagenes";\
		echo "Copiando los escudos a la carpeta ${DIR_TESIS}";\
		cp -R ./figuras  "${DIR_TESIS}";\
		echo "Copiando este archivo a la carpeta ${DIR_TESIS}";\
		cp ./Makefile "${DIR_TESIS}";\
	fi;

#	texhash


# Imprime la ayuda
ayuda : info
	@echo ""
	@echo ""
	@echo "==========================================="
	@echo "Cmd             Descripcion"
	@echo "==========================================="
	@echo "dvi      [DEFAULT]Crea archivos DVI por cada archivo fuente"
	@echo "pdf      Crea un PDF por cada archivo fuente"
	@echo "ps       Crea archivos PostScript por cada archivo fuente "
	@echo
	@echo "borrar   Borra los archivos inecesarios."
	@echo "limpiar  Borra los archivos inecesarios (incluye PDFs, PSs y DVIs)"
	@echo 
	@echo "tar      Empaqueta los archivos para distribuirlos (formato tar.bz2)"


info :
	@echo ""
	@echo ""
	@echo "=========================================="
	@echo "===       Archivos TeX Principales     ==="
	@echo "=========================================="
	@echo ${TEX_PRINCIPAL}
	@echo ""
	@echo ""
	@echo "=========================================="
	@echo "=== Archivos que muestran bibliografía ==="
	@echo "=========================================="
	@echo ${ARCHIVOS_BIBTEX}
	@echo ""
	@echo ""
	@echo "=========================================="
	@echo "===           Archivos Fuente          ==="
	@echo "=========================================="
	@echo ${ARCHIVOS_TEX}

ver : dvi
	$(DVIVIEWER) ${TEX_PRINCIPAL} &

ver-ps: ps
	$(PSVIEWER) ${PS_PRINCIPAL} &

ver-pdf: pdf
	$(PDFVIEWER) ${PDF_PRINCIPAL} &
