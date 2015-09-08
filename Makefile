manuscript = paper
references = $(wildcard *.bib)
latexopt   = -halt-on-error -file-line-error

figs = sync-cycle.eps detail-power.eps detail-power-rel.eps detail-unfueled.eps detail-badshare.eps detail-puinv.eps

all: all-via-pdf

all-via-pdf: $(manuscript).tex $(references)
	pdflatex $(latexopt) $<
	bibtex $(manuscript).aux
	pdflatex $(latexopt) $<
	pdflatex $(latexopt) $<

all-via-dvi: 
	latex $(latexopt) $(manuscript)
	bibtex $(manuscript).aux
	latex $(latexopt) $(manuscript)
	latex $(latexopt) $(manuscript)
	dvipdf $(manuscript)

epub: 
	latex $(latexopt) $(manuscript)
	bibtex $(manuscript).aux
	mk4ht htlatex $(manuscript).tex 'xhtml,charset=utf-8,pmathml' ' -cunihtf -utf8 -cvalidate'
	ebook-convert $(manuscript).html $(manuscript).epub

clean:
	rm -f *.pdf *.dvi *.toc *.aux *.out *.log *.bbl *.blg *.log *.spl *~ *.spl *.zip *.acn *.glo *.ist *.epub

realclean: clean
	rm -rf $(manuscript).dvi
	rm -f $(manuscript).pdf

%.ps :%.eps
	convert $< $@

%.png :%.eps
	convert $< $@

zip:
	zip paper.zip *.tex *.eps *.bib

.PHONY: all clean

sync-cycle.eps: exp2/sync-cycle.gp exp2/sync-cycle-power.dat
	bash -c "cd exp2; gnuplot sync-cycle.gp"
	cp exp2/sync-cycle.eps $@

detail-power.eps: exp2/power.gp exp2/power.dat
	bash -c "cd exp2; gnuplot power.gp"
	cp exp2/power.eps $@

detail-power-rel.eps: exp2/power-rel.gp exp2/power.dat
	bash -c "cd exp2; gnuplot power-rel.gp"
	cp exp2/power-rel.eps $@

detail-unfueled.eps: exp2/unfueled.gp exp2/unfueled.dat
	bash -c "cd exp2; gnuplot unfueled.gp"
	cp exp2/unfueled.eps $@

detail-puinv.eps: exp2/puinv.gp exp2/puinv.dat exp2/puflowin.dat exp2/puflow.dat
	bash -c "cd exp2; gnuplot puinv.gp"
	cp exp2/puinv.eps $@

detail-badshare.eps: exp2/badshare.gp exp2/badshare.dat
	bash -c "cd exp2; gnuplot badshare.gp"
	cp exp2/badshare.eps $@

