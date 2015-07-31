;;; multimu4e.el --- Facilitate the configuration of multiple accounts in mu4e

;; Copyright (C) 2015 Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Facilitate the configuration of multiple accounts in mu4e

;;; Code:

(require 'message)
(require 'cus-edit)
(require 'mu4e-message)

(defgroup multimu4e nil
  "mu4e - mu for emacs"
  :group 'mu4e)

(defconst multimu4e--account-variables
  '(mu4e-trash-folder
    user-mail-address
    multimu4e-account-maildir
    mu4e-sent-folder
    mu4e-sent-messages-behavior
    mu4e-drafts-folder
    mu4e-compose-signature
    smtpmail-queue-dir
    smtpmail-local-domain
    smtpmail-smtp-user
    smtpmail-smtp-server
    smtpmail-stream-type
    smtpmail-smtp-service
    )
  "List of variables that a user may want to assign by account.")

(defconst multimu4e--account-variable-options
  (mapcar (lambda (varname) `((variable-item ,varname) ,(custom-variable-type varname)))
          multimu4e--account-variables)
  "Option list suitable for `defcustom' based on `multimu4e--account-variables'.")

;; TODO: make sure that multimu4e--account-alist has a multimu4e-account-maildir
;;       for each account.

(defcustom multimu4e-account-alist nil
  "List of mu4e accounts."
  :group 'multimu4e
  :type `(alist
          :key-type (string :tag "Account name")
          :value-type (alist
                       :tag "Variables to set"
                       :key-type variable
                       :options ,multimu4e--account-variable-options)))

(defun multimu4e-account-names ()
  "Return a list of all user account names.
This list is extracted from `multimu4e-account-alist'."
  (mapcar #'car multimu4e-account-alist))

(defun multimu4e--choose-account ()
  "Ask the user to choose an account from `multimu4e-account-alist'."
  (let ((account-names (multimu4e-account-names)))
    (multimu4e--account-with-name
     (completing-read "Compose with account: "
                      account-names
                      nil t nil nil (car account-names)))))

(defun multimu4e--name (account)
  "Return the name of ACCOUNT."
  (car account))

(defun multimu4e--bindings (account)
  "Return an alist of all bindings for ACCOUNT in `multimu4e-account-alist."
  (cdr account))

(defun multimu4e--binding-value-for-account (account binding-name)
  "For ACCOUNT, get the value associated with BINDING-NAME."
  (cdr (assoc binding-name
              (multimu4e--bindings account))))

(defun multimu4e--account-with-name (account-name)
  "Return the account with ACCOUNT-NAME."
  (cl-find account-name
           multimu4e-account-alist
           :test #'string=
           :key #'car))

(defun multimu4e--binding-name (binding)
  "Return the name of BINDING."
  (car binding))

(defun multimu4e--binding-value (binding)
  "Return the value of BINDING."
  (cdr binding))

(defun multimu4e--accounts-for-binding (binding &optional test)
  "Return all accounts of `multimu4e-account-alist' with BINDING.
Use TEST to compare the BINDING value against the binding values for each
account.  TEST is a 2-arg function taking the account binding value and the
BINDING value as argument in this order.  TEST defaults to `equal'."
  (let ((test (or test #'equal)))
    (cl-remove-if-not
     (lambda (binding-value)
       (funcall test (multimu4e--binding-value binding) binding-value))
     multimu4e-account-alist
     :key (lambda (account)
            (multimu4e--binding-value-for-account account
                                                  (multimu4e--binding-name binding))))))

(defun multimu4e--account-for-binding (binding &optional test)
  "Return the first account of `multimu4e-account-alist' with BINDING.
Use TEST to compare the BINDING value against the binding values for each
account.  TEST is a 2-arg function taking the account binding value and the
BINDING value as argument in this order.  TEST defaults to `equal'.
Nil is returned if no account is found."
  (car (multimu4e--accounts-for-binding binding test)))

(defun multimu4e--guess-account-from-message (message)
  "Guess the account related to MESSAGE.
In practice, look at the maildir containing MESSAGE and return the account
responsible for this maildir by searching a binding of
`multimu4e-account-maildir' in `multimu4e-account-alist'."
  (multimu4e--account-for-binding
   (cons 'multimu4e-account-maildir
         (mu4e-message-field message :maildir))
   (lambda (actual expected)
     (string-match (format "^%s" (regexp-quote expected))
                   actual))))

(defun multimu4e--guess-account-in-compose ()
  "Guess the account best suited to compose a new message.
If the new message is an answer to an existing email this function returns
the account the original email was sent to.  If no account can be guessed,
return nil."
  (when (and (boundp 'mu4e-compose-parent-message)
             mu4e-compose-parent-message)
    (multimu4e--guess-account-from-message mu4e-compose-parent-message)))

;;;###autoload
(defun multimu4e-set-account (account)
  "Set all bindings of ACCOUNT."
  (interactive (list (multimu4e--choose-account)))
  (mapc (lambda (binding) (set (multimu4e--binding-name binding)
                          (multimu4e--binding-value binding)))
        (multimu4e--bindings account)))

;;;###autoload
(defun multimu4e-set-account-in-compose ()
  "Set all bindings of the account best suited to compose."
  (multimu4e-set-account (or (multimu4e--guess-account-in-compose)
                             (multimu4e--choose-account))))

(defun multimu4e--change-from-in-compose (&optional name address)
  "Change the From: of current message using NAME and ADDRESS.
The From: field is changed to be \"USER <ADDRESS>\".

If NAME or ADDRESS are not provided, use the variables `user-full-name' and
`user-mail-address'."
  (save-excursion
    (message-goto-from)
    (message-beginning-of-line)
    (kill-line)
    (insert (format "%s <%s>"
                    (or name user-full-name)
                    (or address user-mail-address)))))

(defun multimu4e--change-signature-in-compose ()
  "Change the signature of the current message."
  (save-excursion
    (set (make-local-variable 'message-signature) mu4e-compose-signature)
    (message-goto-signature)
    (message-beginning-of-line)
    (previous-line 2)
    (delete-region (point) (point-max))
    (message-insert-signature)))

;;;###autoload
(defun multimu4e-set-account-from-name (account-name)
  "Set all bindings of account named ACCOUNT-NAME."
  (multimu4e-set-account (multimu4e--account-with-name account-name)))

(defun multimu4e-force-account-in-compose (account)
  "Bind all ACCOUNT variables and modify the From: field of current message.
Interactively, ask the user for the account to use."
  (interactive (list (multimu4e--choose-account)))
  (multimu4e-set-account account)
  (multimu4e--change-from-in-compose)
  (multimu4e--change-signature-in-compose))

(provide 'multimu4e)

;;; multimu4e.el ends here

;;  LocalWords:  alist maildir
