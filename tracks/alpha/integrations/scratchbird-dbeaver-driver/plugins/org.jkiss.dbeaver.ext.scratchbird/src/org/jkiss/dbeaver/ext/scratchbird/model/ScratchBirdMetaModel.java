/*
 * DBeaver - Universal Database Manager
 * Copyright (C) 2010-2026 DBeaver Corp and others
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.jkiss.dbeaver.ext.scratchbird.model;

import org.jkiss.code.NotNull;
import org.jkiss.code.Nullable;
import org.jkiss.dbeaver.DBException;
import org.jkiss.dbeaver.ext.generic.model.GenericCatalog;
import org.jkiss.dbeaver.ext.generic.model.GenericDataSource;
import org.jkiss.dbeaver.ext.generic.model.GenericSQLDialect;
import org.jkiss.dbeaver.ext.generic.model.GenericSchema;
import org.jkiss.dbeaver.ext.generic.model.meta.GenericMetaModel;
import org.jkiss.dbeaver.model.DBPDataSourceContainer;
import org.jkiss.dbeaver.model.runtime.DBRProgressMonitor;

import java.util.Locale;

public class ScratchBirdMetaModel extends GenericMetaModel {

    @NotNull
    @Override
    public GenericDataSource createDataSourceImpl(
        @NotNull DBRProgressMonitor monitor,
        @NotNull DBPDataSourceContainer container
    ) throws DBException {
        return new ScratchBirdDataSource(monitor, container, this, new GenericSQLDialect());
    }

    @Override
    public GenericCatalog createCatalogImpl(@NotNull GenericDataSource dataSource, @NotNull String catalogName) {
        return new ScratchBirdCatalog(dataSource, catalogName);
    }

    @Override
    public boolean useCatalogInObjectNames() {
        return false;
    }

    @Override
    public boolean isSystemSchema(@NotNull GenericSchema schema) {
        final String name = schema.getName();
        if (name == null) {
            return false;
        }
        String normalized = name.toLowerCase(Locale.ENGLISH);
        return normalized.equals("sys") || normalized.startsWith("sys.");
    }

    @Override
    public GenericSchema createSchemaImpl(
        @NotNull GenericDataSource dataSource,
        @Nullable GenericCatalog catalog,
        @NotNull String schemaName
    ) throws DBException {
        return new GenericSchema(dataSource, catalog, schemaName);
    }
}
