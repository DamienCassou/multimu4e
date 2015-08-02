;;; multimu4e-tests.el --- Tests for multimu4e.el

;; Copyright (C) 2013 Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>

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

;; Tests for multimu4e.el

;;; Code:

(require 'ert)

(require 'multimu4e)

(eval-when-compile (require 'cl-macs))

(setq multimu4e-account-alist
      '(("Account1"
         (user-mail-address . "me@account1.fr")
         (multimu4e-account-maildir . "/Maildir1"))
        ("Account2"
         (user-mail-address . "me@account2.fr")
         (multimu4e-account-maildir . "/Maildir2"))))

(ert-deftest multimu4e-tests-account-names ()
  (should (equal '("Account1" "Account2")
                 (multimu4e-account-names))))

(ert-deftest multimu4e-tests-name ()
  (should (equal "Account1"
                 (multimu4e--name (car multimu4e-account-alist)))))

(ert-deftest multimu4e-tests-bindings ()
  (should (equal '((user-mail-address . "me@account1.fr")
                   (multimu4e-account-maildir . "/Maildir1"))
                 (multimu4e--bindings (car multimu4e-account-alist)))))

(ert-deftest multimu4e-tests-binding-value ()
  (should (equal "me@account1.fr"
                 (multimu4e--binding-value-for-account
                  (car multimu4e-account-alist)
                  'user-mail-address))))

(ert-deftest multimu4e-tests-account-with-name ()
  (should (equal (car multimu4e-account-alist)
                 (multimu4e--account-with-name "Account1"))))

(ert-deftest multimu4e-tests-accounts-for-binding ()
  (should (equal (list (car multimu4e-account-alist))
                 (multimu4e--accounts-for-binding
                  (cons 'multimu4e-account-maildir "/Maildir1")))))

(ert-deftest multimu4e-tests-account-for-binding ()
  (should (equal (car multimu4e-account-alist)
                 (multimu4e--account-for-binding
                  (cons 'multimu4e-account-maildir "/Maildir1")))))

(ert-deftest multimu4e-tests-account-for-binding-with-nil ()
  (should (null
           (multimu4e--accounts-for-binding
            (cons 'multimu4e-account-maildir "DOES NOT EXIST")))))

(ert-deftest multimu4e-tests-guess-account-from-message ()
  (should (equal (car multimu4e-account-alist)
                 (multimu4e--guess-account-from-message
                  `(:maildir "/Maildir1")))))

(ert-deftest multimu4e-tests-guess-account-from-message-subdir ()
  (should (equal (car multimu4e-account-alist)
                 (multimu4e--guess-account-from-message
                  `(:maildir "/Maildir1/SubDir")))))

(eval-when-compile (defvar multimu4e-account-maildir))

(ert-deftest multimu4e-tests-set-account ()
  (should-not (boundp 'multimu4e-account-maildir))
  (multimu4e-set-account (car multimu4e-account-alist))
  (should (boundp 'multimu4e-account-maildir))
  (should (equal "/Maildir1" multimu4e-account-maildir)))

(ert-deftest multimu4e-tests-change-from-in-compose ()
  (with-current-buffer (get-buffer-create "*ert-multimu4e*")
    (insert "From: foo\n--text follows this line--\n")
    (multimu4e--change-from-in-compose "bar" "baz")
    (message-goto-from)
    (message-beginning-of-line)
    (should (looking-at "bar <baz>"))))

(ert-deftest multimu4e-tests-change-from-in-compose-defaults ()
  (with-current-buffer (get-buffer-create "*ert-multimu4e*")
    (insert "From: foo\n--text follows this line--\n")
    (setq user-full-name "bar" user-mail-address "baz")
    (multimu4e--change-from-in-compose)
    (message-goto-from)
    (message-beginning-of-line)
    (cl-assert
     (looking-at "bar <baz>")
     nil
     "Was looking at %s"
     (buffer-substring-no-properties (point) (point-at-eol)))))

(ert-deftest multimu4e-tests-change-signature-in-compose-with-newline ()
  (with-current-buffer (get-buffer-create "*ert-multimu4el-w-newline*")
    (insert "From: foo\n--text follows this line--\ncontent\n\n-- \nold signature")
    (setq mu4e-compose-signature "new signature")
    (multimu4e--change-signature-in-compose)
    (message-goto-signature)
    (previous-line 3)
    (message-beginning-of-line)
    (should (looking-at "content\n\n-- \nnew signature\n"))))

(ert-deftest multimu4e-tests-change-signature-in-compose-without-newline ()
  (with-current-buffer (get-buffer-create "*ert-multimu4el-wo-newline*")
    (insert "From: foo\n--text follows this line--\ncontent\n-- \nold signature")
    (setq mu4e-compose-signature "new signature")
    (multimu4e--change-signature-in-compose)
    (message-goto-signature)
    (previous-line 2)
    (message-beginning-of-line)
    (should (looking-at "content\n-- \nnew signature\n"))))

(ert-deftest multimu4e-tests-change-signature-in-compose-without-signature ()
  (with-current-buffer (get-buffer-create "*ert-multimu4el-wo-signature*")
    (insert "From: foo\n--text follows this line-- \ncontent")
    (setq mu4e-compose-signature "new signature")
    (multimu4e--change-signature-in-compose)
    (message-goto-signature)
    (message-beginning-of-line)
    (should (looking-at "new signature"))))

(provide 'multimu4e-tests)

;;; multimu4e-tests.el ends here
