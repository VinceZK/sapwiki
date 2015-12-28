(ert-deftest dk-html-tag-test ()
  (find-file "example.html")
  (goto-char (point-min))
  (should (equal (dk-search-html-tag) '("<h1>" 1 . 5)))
  (should (equal (dk-search-html-tag) '("<ac:macro/>" 5 . 31)))
  (should (equal (dk-search-html-tag) '("</h1>" 31 . 36)))
  (should (equal (dk-search-html-tag) '("<h2>" 37 . 41)))
  (let ((beg-tag (dk-search-html-tag))
	(end-tag (dk-search-html-tag)))
    (should (equal (buffer-substring-no-properties
		    (cdr (cdr beg-tag))
		    (car (cdr end-tag)))
		   "1"))))

(ert-deftest dk-check-valid-html-tag ()
  (should (dk-check-valid-html-tag "<h2>"))
  (should (dk-check-valid-html-tag "<br/>"))
  (should (dk-check-valid-html-tag "<p/>"))
  (should (dk-check-begin-html-tag "<table>")))

(ert-deftest dk-html-end-tag-test ()
  (should (dk-check-end-html-tag "</p>"))
  (should (equal (dk-get-html-end-tag "<p>") "</p>"))
  (should (equal (dk-get-html-end-tag "<div>") "</div>")))

(ert-deftest dk-add-tag-to-begin-tag-list ()
  (let ((html-tag '("<h2>" 1 . 5)))
    (dk-process-html-begin-tag html-tag)
  (should (equal (car (nth 0 begin-tag-list))
		 html-tag))
  (should (eq (cdr (nth 0 begin-tag-list))
	      (get-buffer "<h2>"))))
  (kill-buffer "<h2>")) 

(ert-deftest dk-process-html-begin-tag ()
  (let ((html-tag '("<h2>" 1 . 5)))
    (dk-process-html-begin-tag html-tag)
    (should (equal (car (nth 0 begin-tag-list))
		   html-tag))
    (should (eq (cdr (nth 0 begin-tag-list))
		(get-buffer "<h2>"))))
  (kill-buffer "<h2>"))
  
(ert-deftest dk-iterate-html-tag ()
  (find-file "example.html")
  (with-current-buffer result-org-buffer
    (erase-buffer)) 
  (dk-iterate-html-tag)
  (switch-to-buffer result-org-buffer))

(ert-deftest dk-http-get ()
  (dk-url-http-get "https://wiki.wdf.sap.corp/wiki/pages/editpage.action"
		    '(("pageId" . "1774869651"))
		    'dk-switch-to-url-buffer))
  
(ert-deftest dk-sapwiki-login ()
 (dk-sapwiki-login))

(ert-deftest dk-sapwiki-fetch ()
  (find-file "/work/test01.org")
  (should (equal (dk-sapwiki-get-attribute-value "PAGEID")
		 "1774869651"))
  (dk-sapwiki-fetch))

(ert-deftest dk-attachment-upload ()
  (dk-url-http-get
   dk-sapwiki-lock-url 
   (list (cons "pageId"  "1774869651"))
   (lambda (status)
     (set-buffer (current-buffer))
     (goto-char 1)
     (let* ((atl-tokenv (progn 
			 (re-search-forward "\\(<meta name=\"ajs-atl-token\" content=\"\\)\\([^\"]+\\)" nil t)
			 (buffer-substring (match-beginning 2) (match-end 2)))))
       (dk-url-http-post-multipart dk-sapwiki-upload-url 
       				   (list (cons "pageId"  "1774869651"))
       				   (list (cons 'atl_token atl-tokenv)
					 (cons 'comment_0 "Uploaded by emacs!")
					 (cons 'confirm "Attach"))
       				   (list (list 'file_0  "DecisionTable.png" "image/png"
					       (with-temp-buffer
						 (insert-file-contents "image/DecisionTable.png")
						 (buffer-substring-no-properties (point-min) (point-max)))))
       				   'dk-switch-to-url-buffer)))))

(ert-deftest dk-collect-attachments ()
  (should (equal (dk-get-mime-type "DecisionTable.png")
  		 "image/png"))
  (should (equal (length (dk-get-attachment-rawdata
  			  "image/DecisionTable.png"))
  		 21362))
  (setq dk-sapwiki-attachments ())
  (dk-collect-attachments "image/DecisionTable.png")
  (should (equal (symbol-name (car (car dk-sapwiki-attachments))) "file_0"))
  (dk-collect-attachments "image/TextRuleEditor.png")
  (should (equal (symbol-name (car (car dk-sapwiki-attachments))) "file_1"))
  (setq dk-sapwiki-attachments ()))
